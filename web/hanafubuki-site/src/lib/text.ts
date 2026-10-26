import config from '../config.json';

const escape = (s: string) =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

/** Плейсхолдеры из конфига: {host}, {port}. */
export const fill = (s: string) =>
  s.replace(/\{host\}/g, config.server.host).replace(/\{port\}/g, String(config.server.bedrockPort));

/**
 * Мини-разметка для текстов из site.*.json: **жирный**, *курсив*, `код`.
 * Сначала экранируем HTML, поэтому в текстах нельзя случайно сломать страницу.
 */
export const md = (s: string) =>
  escape(fill(s))
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
    .replace(/\*([^*]+)\*/g, '<em>$1</em>');
