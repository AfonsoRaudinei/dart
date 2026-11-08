function bytesToBase64Url(bytes: Uint8Array): string {
  let binary = ''
  for (const byte of bytes) binary += String.fromCharCode(byte)
  return btoa(binary).replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '')
}

function pemToDer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----BEGIN [^-]+-----/g, '')
    .replace(/-----END [^-]+-----/g, '')
    .replace(/\s/g, '')
  const binary = atob(b64)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i)
  return bytes.buffer
}

async function signJwt(
  algorithm: 'ES256' | 'RS256',
  privateKeyPem: string,
  header: Record<string, unknown>,
  payload: Record<string, unknown>,
): Promise<string> {
  const encodedHeader = bytesToBase64Url(new TextEncoder().encode(JSON.stringify(header)))
  const encodedPayload = bytesToBase64Url(new TextEncoder().encode(JSON.stringify(payload)))
  const signingInput = `${encodedHeader}.${encodedPayload}`
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(privateKeyPem),
    algorithm === 'ES256'
      ? { name: 'ECDSA', namedCurve: 'P-256' }
      : { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const signature = await crypto.subtle.sign(
    algorithm === 'ES256'
      ? { name: 'ECDSA', hash: 'SHA-256' }
      : { name: 'RSASSA-PKCS1-v1_5' },
    key,
    new TextEncoder().encode(signingInput),
  )
  return `${signingInput}.${bytesToBase64Url(new Uint8Array(signature))}`
}

export function signEs256Jwt(
  privateKeyPem: string,
  keyId: string,
  payload: Record<string, unknown>,
): Promise<string> {
  return signJwt('ES256', privateKeyPem, { alg: 'ES256', kid: keyId, typ: 'JWT' }, payload)
}

export function signRs256Jwt(
  privateKeyPem: string,
  payload: Record<string, unknown>,
): Promise<string> {
  return signJwt('RS256', privateKeyPem, { alg: 'RS256', typ: 'JWT' }, payload)
}
