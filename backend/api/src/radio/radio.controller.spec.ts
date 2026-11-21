import { RadioService } from './radio.service';
import { RadioController } from './radio.controller';

describe('RadioController', () => {
  it('delegates station directory requests to RadioService', async () => {
    const stations = [{ id: 'station-1' }];
    const radio = {
      listStations: jest.fn().mockResolvedValue(stations),
      getStation: jest.fn(),
      programsForStation: jest.fn(),
    };
    const controller = new RadioController(radio as unknown as RadioService);

    await expect(controller.stations()).resolves.toBe(stations);
    expect(radio.listStations).toHaveBeenCalledTimes(1);
  });

  it('delegates station detail and schedule requests', async () => {
    const station = { id: 'station-1', programs: [] };
    const programs = [{ id: 'program-1' }];
    const radio = {
      listStations: jest.fn(),
      getStation: jest.fn().mockResolvedValue(station),
      programsForStation: jest.fn().mockResolvedValue(programs),
    };
    const controller = new RadioController(radio as unknown as RadioService);

    await expect(controller.station('station-1')).resolves.toBe(station);
    await expect(controller.programs('station-1')).resolves.toBe(programs);
    expect(radio.getStation).toHaveBeenCalledWith('station-1');
    expect(radio.programsForStation).toHaveBeenCalledWith('station-1');
  });
});
