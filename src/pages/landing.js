export function renderLanding(container, onGetStarted) {
  container.innerHTML = `
    <div class="landing">
      <section class="landing-hero">
        <div class="landing-hero-content">
          <h1>🔥 Fasting Furious</h1>
          <p class="landing-tagline">train hard. fast harder.</p>
          <p class="landing-description">Track your fasts, workouts, and daily progress with friends. Turn your health journey into a game.</p>
          <div class="landing-cta">
            <button id="landing-get-started" class="btn btn-primary btn-lg">Get Started Free</button>
            <button id="landing-sign-in" class="btn btn-secondary btn-lg">Sign In</button>
          </div>
        </div>
      </section>

      <section class="landing-features">
        <h2>Your fitness, RPG-style</h2>
        <div class="landing-feature-grid">
          <div class="landing-feature-card">
            <div class="feature-icon">⏱️</div>
            <h3>Smart Timers</h3>
            <p>Track fasting and workout sessions with live countdown timers. Get notified when you complete your goals.</p>
          </div>
          <div class="landing-feature-card">
            <div class="feature-icon">👥</div>
            <h3>Friend Cards</h3>
            <p>See your friends' daily activity as Pokémon-style trading cards. Give kudos and stay motivated together.</p>
          </div>
          <div class="landing-feature-card">
            <div class="feature-icon">🏆</div>
            <h3>Streaks &amp; Ranks</h3>
            <p>Earn titles and rare card borders based on your activity. The more you show up, the more you unlock.</p>
          </div>
        </div>
      </section>

      <section class="landing-cta-section">
        <h2>Ready to level up?</h2>
        <p>Join your friends. Track your progress. Get stronger every day.</p>
        <button id="landing-cta-bottom" class="btn btn-primary btn-lg">Get Started Now</button>
      </section>

      <footer class="landing-footer">
        <p>Fasting Furious &mdash; train hard. fast harder.</p>
      </footer>
    </div>
  `

  const triggers = container.querySelectorAll('#landing-get-started, #landing-sign-in, #landing-cta-bottom')
  triggers.forEach(btn => btn.addEventListener('click', onGetStarted))

  return () => { container.innerHTML = '' }
}
