import { spawn } from 'child_process';
import * as fs from 'fs/promises';
import * as path from 'path';

// Plan §10.2 — pipeline stages. FFmpeg/FFprobe are the real tools.
// Per-variant HLS renditions under media/<jobId>/.

export interface ProbeResult {
  durationSec: number;
  codec: string;
  sampleRateHz: number;
  bitrateKbps: number;
}

function run(cmd: string, args: string[]): Promise<string> {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    let stdout = '';
    child.stdout.on('data', (d: Buffer) => (stdout += d.toString()));
    child.on('error', reject);
    child.on('close', (code) => {
      if (code === 0) resolve(stdout);
      else reject(new Error(`${cmd} exited with code ${code}`));
    });
  });
}

export async function probe(inputPath: string): Promise<ProbeResult> {
  const out = await run('ffprobe', [
    '-v', 'error',
    '-print_format', 'json',
    '-show_format',
    '-show_streams',
    inputPath,
  ]);
  const parsed = JSON.parse(out) as {
    format: { duration: string; bit_rate: string };
    streams?: { codec_name: string; sample_rate?: string }[];
  };
  const audio = parsed.streams?.find((s) => !!s.sample_rate);
  return {
    durationSec: Number(parsed.format.duration),
    codec: audio?.codec_name ?? 'unknown',
    sampleRateHz: Number(audio?.sample_rate ?? 0),
    bitrateKbps: Math.round(Number(parsed.format.bit_rate) / 1000),
  };
}

export async function validate(inputPath: string): Promise<ProbeResult> {
  const result = await probe(inputPath).catch(() => null);
  if (
    !result ||
    !Number.isFinite(result.durationSec) ||
    result.durationSec <= 0
  ) {
    throw new Error('PROBE_FAILED_NOT_PLAYABLE');
  }
  return result;
}

// Transcodes each variant with its own ffmpeg invocation — clear,
// debuggable, one variant per process.
export async function transcodeVariant(
  inputPath: string,
  outDir: string,
  label: string,
  kbps: number,
): Promise<string> {
  await fs.mkdir(outDir, { recursive: true });
  const playlist = path.join(outDir, `${label}.m3u8`);
  await run('ffmpeg', [
    '-y',
    '-i', inputPath,
    '-c:a', 'aac',
    '-b:a', `${kbps}k`,
    '-hls_time', '6',
    '-hls_playlist_type', 'vod',
    '-hls_segment_filename', path.join(outDir, `${label}_%03d.ts`),
    playlist,
  ]);
  return playlist;
}

export async function writeMasterPlaylist(
  outDir: string,
  variants: string[],
): Promise<string> {
  const lines = ['#EXTM3U'];
  for (const v of variants) {
    lines.push(`#EXT-X-STREAM-INF:BANDWIDTH=256000,CODECS="mp4a.40.2"`);
    lines.push(v);
  }
  const master = path.join(outDir, 'master.m3u8');
  await fs.writeFile(master, lines.join('\n'), 'utf8');
  return master;
}

export async function transcodeAll(
  inputPath: string,
  outDir: string,
): Promise<string> {
  const playlists: string[] = [];
  playlists.push(await transcodeVariant(inputPath, outDir, 'aac_128', 128));
  playlists.push(await transcodeVariant(inputPath, outDir, 'aac_256', 256));
  return writeMasterPlaylist(outDir, playlists.map((p) => path.basename(p)));
}
