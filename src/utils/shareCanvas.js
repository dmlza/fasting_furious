export function renderShareCanvas({ profile, habits, timer }) {
  const canvas = document.createElement('canvas')
  canvas.width = 600
  canvas.height = 800
  const ctx = canvas.getContext('2d')

  const bg = '#FDFBF7'
  ctx.fillStyle = bg
  ctx.fillRect(0, 0, 600, 800)

  // Header
  ctx.fillStyle = '#1A1A1A'
  ctx.font = 'bold 24px Inter, sans-serif'
  ctx.textAlign = 'center'
  ctx.fillText('🔥 Fasting Furious', 300, 60)

  ctx.font = '14px Inter, sans-serif'
  ctx.fillStyle = '#A39B94'
  ctx.fillText(profile?.display_name || profile?.username || 'Anonymous', 300, 85)

  // Habits
  const habitItems = [
    { key: 'exercise', icon: '🏃', label: 'Exercise', done: habits?.exercise },
    { key: 'no_sugar', icon: '🍬', label: 'No Sugar', done: habits?.no_sugar },
    { key: 'no_smoking', icon: '🚭', label: 'No Smoking', done: habits?.no_smoking },
  ]

  let y = 130
  habitItems.forEach(h => {
    ctx.fillStyle = '#FFFFFF'
    roundRect(ctx, 60, y, 480, 50, 16)
    ctx.fill()

    ctx.font = '24px sans-serif'
    ctx.textAlign = 'left'
    ctx.fillText(h.icon, 80, y + 35)

    ctx.font = '600 15px Inter, sans-serif'
    ctx.fillStyle = '#1A1A1A'
    ctx.fillText(h.label, 120, y + 28)

    ctx.font = '13px Inter, sans-serif'
    ctx.fillStyle = h.done ? '#6CB49C' : '#A39B94'
    ctx.fillText(h.done ? '✅ Done' : '⬜ Pending', 120, y + 44)

    y += 62
  })

  // Timer status
  if (timer) {
    y += 10
    ctx.fillStyle = '#E2ECE9'
    roundRect(ctx, 60, y, 480, 70, 16)
    ctx.fill()

    ctx.font = '14px Inter, sans-serif'
    ctx.fillStyle = '#4A7A6E'
    ctx.textAlign = 'center'
    ctx.fillText('⏱️ Currently Fasting', 300, y + 30)
    ctx.font = '600 18px Inter, sans-serif'
    ctx.fillText(`${Math.floor(timer.target_minutes / 60)}:${String(timer.target_minutes % 60).padStart(2, '0')}h target`, 300, y + 58)
  }

  // Footer
  ctx.font = '13px Inter, sans-serif'
  ctx.fillStyle = '#A39B94'
  ctx.textAlign = 'center'
  ctx.fillText('Join me on Fasting Furious!', 300, 750)

  return canvas
}

function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath()
  ctx.moveTo(x + r, y)
  ctx.lineTo(x + w - r, y)
  ctx.quadraticCurveTo(x + w, y, x + w, y + r)
  ctx.lineTo(x + w, y + h - r)
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
  ctx.lineTo(x + r, y + h)
  ctx.quadraticCurveTo(x, y + h, x, y + h - r)
  ctx.lineTo(x, y + r)
  ctx.quadraticCurveTo(x, y, x + r, y)
  ctx.closePath()
}
