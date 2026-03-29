# Design Instincts

<!-- Format: confidence | trigger → action (source, date) -->
0.8 | building HTML presentations → swapping CSS tokens is NOT a redesign; each presentation needs unique visual identity with dramatic type/layout choices (correction x2, 2026-03-29)
0.8 | choosing presentation aesthetics → audience emotion drives design: urgency=bold+glow, trust=editorial+restraint, clarity=clean+whitespace (pattern, 2026-03-29)
0.7 | using modern CSS (OKLCH relative colors) → use hex/rgba in production HTML for browser compatibility; OKLCH breaks older browsers (correction, 2026-03-29)
0.7 | loading web fonts → verify CDN URL returns 200 before committing; Geist font 404 broke entire page (correction, 2026-03-29)
