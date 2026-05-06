/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        sidebar: '#0D1B2A',
        primary: '#1A73E8',
        success: '#00C853',
        warning: '#FF6D00',
        danger: '#D32F2F',
      },
    },
  },
  plugins: [],
}
