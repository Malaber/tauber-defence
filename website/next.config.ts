import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  output: 'export',
  // vinext's current export probe follows canonical redirects before it can
  // write directory indexes. Build extension files first; the post-build step
  // mirrors them to `/route/index.html` for clean GitHub Pages URLs.
  trailingSlash: false,
};

export default nextConfig;
