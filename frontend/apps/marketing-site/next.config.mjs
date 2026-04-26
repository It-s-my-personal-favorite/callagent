/** @type {import('next').NextConfig} */
const securityHeaders = [
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  {
    key: 'Permissions-Policy',
    value: 'camera=(), microphone=(), geolocation=(), interest-cohort=()',
  },
  {
    key: 'Strict-Transport-Security',
    value: 'max-age=31536000; includeSubDomains; preload',
  },
]

const nextConfig = {
  // Minimaler Laufzeit-Image für Docker (siehe Dockerfile im Projektordner)
  output: 'standalone',
  experimental: {
    optimizePackageImports: [
      'lucide-react',
      '@radix-ui/react-dialog',
      '@radix-ui/react-accordion',
      'next-themes',
    ],
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  async headers() {
    return [{ source: '/:path*', headers: securityHeaders }]
  },
  async rewrites() {
    const upstream = process.env.CALLAGENT_APP_UPSTREAM?.trim().replace(/\/$/, '')
    const proxyHost = process.env.CALLAGENT_APP_PROXY_HOST?.trim()
    if (!upstream || !proxyHost) return []

    return {
      beforeFiles: [
        {
          source: '/:path*',
          has: [{ type: 'host', value: proxyHost }],
          destination: `${upstream}/:path*`,
        },
      ],
    }
  },
}

export default nextConfig
