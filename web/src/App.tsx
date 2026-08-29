import { useState } from 'react'
import AdminApp from './admin/AdminApp'
import OwnerApp from './owner/OwnerApp'
import { useNuiEvent } from './hooks/useNuiEvent'
import { applyTheme } from './lib/theme'
import type { Bootstrap } from './admin/types'
import type { OwnerBootstrap } from './owner/types'

// One ui_page serves every view of this resource. The last "open*" message
// wins, so a new view only needs its own action name and a branch here.
type View = 'none' | 'admin' | 'owner'

export default function App() {
  const [view, setView] = useState<View>('none')
  const [adminBoot, setAdminBoot] = useState<Bootstrap | null>(null)
  const [ownerBoot, setOwnerBoot] = useState<OwnerBootstrap | null>(null)

  useNuiEvent((msg) => {
    if (msg.action === 'openAdmin') {
      const data = msg.data as Bootstrap

      applyTheme(data?.settings?.Theme)
      setAdminBoot(data)
      setView('admin')
      return
    }

    if (msg.action === 'openOwner') {
      // The owner dashboard inherits whatever theme the admin set; the payload
      // carries no colours of its own.
      setOwnerBoot(msg.data as OwnerBootstrap)
      setView('owner')
      return
    }

    if (msg.action === 'close') {
      setView('none')
    }
  })

  if (view === 'admin' && adminBoot) {
    return <AdminApp boot={adminBoot} onBootChange={setAdminBoot} onClose={() => setView('none')} />
  }

  if (view === 'owner' && ownerBoot) {
    return <OwnerApp boot={ownerBoot} onBootChange={setOwnerBoot} onClose={() => setView('none')} />
  }

  return null
}
