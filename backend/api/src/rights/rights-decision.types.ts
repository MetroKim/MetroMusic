export type RightsAction =
  | 'metadata.display'
  | 'preview'
  | 'stream.full'
  | 'download'
  | 'cache'
  | 'video.play'
  | 'lyrics.display'
  | 'lyrics.translate'
  | 'promote';

export interface RightsDecision {
  allowed: boolean;
  reason: string;
  previewOnly: boolean;
  qualityRestriction: string | null;
  expiresAt: Date | null;
  attribution: string | null;
}

export interface RightsRequest {
  userId: string | null;
  trackId: string;
  action: RightsAction;
  territory: string;
}

export function denyDecision(reason: string): RightsDecision {
  return {
    allowed: false,
    reason,
    previewOnly: false,
    qualityRestriction: null,
    expiresAt: null,
    attribution: null,
  };
}

export function allowDecision(p: {
  qualityRestriction: string | null;
  previewOnly?: boolean;
  expiresAt?: Date | null;
  attribution?: string | null;
}): RightsDecision {
  return {
    allowed: true,
    reason: 'OK',
    previewOnly: p.previewOnly ?? false,
    qualityRestriction: p.qualityRestriction,
    expiresAt: p.expiresAt ?? null,
    attribution: p.attribution ?? null,
  };
}
