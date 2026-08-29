const resourceName = (): string => {
  try {
    return GetParentResourceName()
  } catch {
    return 'msk_fuel'
  }
}

const isBrowser = (): boolean => {
  try {
    GetParentResourceName()
    return false
  } catch {
    return true
  }
}

/** Browser-only stand-in for a callback that returns a value. See devMock.ts. */
export type DevResponder = (endpoint: string, data: unknown) => unknown | Promise<unknown>

export async function fetchNui<T = unknown>(
  endpoint: string,
  data: unknown = {},
): Promise<T | null> {
  if (isBrowser()) {
    window.dispatchEvent(new CustomEvent('nui:dev-call', { detail: { endpoint, data } }))
    // Callbacks that stream their answer back as an event (the vehicle lists)
    // are covered by the event above. Callbacks that RETURN a value would be
    // dead in the browser, so devMock can register a responder for them.
    const respond = (window as unknown as { __mskDevRespond?: DevResponder }).__mskDevRespond
    if (typeof respond === 'function') return (await respond(endpoint, data)) as T | null
    return null
  }

  try {
    const resp = await fetch(`https://${resourceName()}/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    })
    if (!resp.ok) return null
    const text = await resp.text()
    return text ? (JSON.parse(text) as T) : null
  } catch {
    return null
  }
}
