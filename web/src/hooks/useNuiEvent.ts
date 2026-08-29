import { useEffect, useRef } from 'react'
import type { IncomingMessage } from '../admin/types'

type Handler = (msg: IncomingMessage) => void

export function useNuiEvent(handler: Handler): void {
  const saved = useRef(handler)
  saved.current = handler

  useEffect(() => {
    const listener = (event: MessageEvent) => {
      const data = event.data as IncomingMessage

      if (data && typeof data.action === 'string') {
        saved.current(data)
      }
    }

    window.addEventListener('message', listener)
    return () => window.removeEventListener('message', listener)
  }, [])
}
