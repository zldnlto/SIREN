import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
  ],
  theme: {
    borderRadius: {
      none: "0px",
      xs: "0px",
      sm: "0px",
      md: "0px",
      lg: "0px",
      xl: "0px",
      xxl: "0px",
      pill: "9999px",
      full: "9999px",
    },
    extend: {
      colors: {
        canvas:   "#010102",
        "surface-1": "#0f1011",
        "surface-2": "#141516",
        "surface-3": "#18191a",
        hairline:  "#23252a",
        "hairline-strong": "#34343a",
        primary:   "#5e6ad2",
        "primary-hover": "#828fff",
        ink:       "#f7f8f8",
        "ink-muted":   "#d0d6e0",
        "ink-subtle":  "#8a8f98",
        "ink-tertiary":"#62666d",
      },
      fontFamily: {
        sans: ["Inter", "SF Pro Display", "system-ui", "sans-serif"],
        mono: ["JetBrains Mono", "SF Mono", "monospace"],
      },
    },
  },
  plugins: [],
};

export default config;
