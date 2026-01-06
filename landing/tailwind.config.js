/** @type {import('tailwindcss').Config} */
module.exports = {
    content: [
        "./src/**/*.{html,ts}",
    ],
    theme: {
        extend: {
            colors: {
                'tenis-green': '#2ecc71',
                'tenis-dark': '#2c3e50',
                'tenis-blue': '#3498db',
            },
        },
    },
    plugins: [],
}
