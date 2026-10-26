import { defineConfig } from 'astro/config';
import config from './src/config.json' with { type: 'json' };

export default defineConfig({
  site: config.site.url,
  build: {
    // Весь CSS — прямо в HTML: ни одного блокирующего запроса.
    inlineStylesheets: 'always',
  },
  devToolbar: { enabled: false },
});
