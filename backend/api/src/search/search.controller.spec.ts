import { SearchService } from './search.service';
import { SearchController } from './search.controller';

describe('SearchController', () => {
  it('passes the query to SearchService', async () => {
    const result = { tracks: [], artists: [], albums: [] };
    const searchService = {
      search: jest.fn().mockResolvedValue(result),
    };
    const controller = new SearchController(
      searchService as unknown as SearchService,
    );

    await expect(controller.search('afrobeats')).resolves.toBe(result);
    expect(searchService.search).toHaveBeenCalledWith('afrobeats');
  });

  it('treats a missing query as an empty string', async () => {
    const searchService = {
      search: jest.fn().mockResolvedValue({ tracks: [], artists: [], albums: [] }),
    };
    const controller = new SearchController(
      searchService as unknown as SearchService,
    );

    await controller.search(undefined as unknown as string);
    expect(searchService.search).toHaveBeenCalledWith('');
  });
});
