# Shared Styles for Nonprofit Analytics Tools

This directory contains shared CSS and assets used across all tools in the nonprofit analytics suite.

## Files

- `shared-styles.css` - Common styles used by all tools to ensure consistent branding and user experience

## Usage

Each tool app should include the shared styles using:

```r
# Add at the top of your app.R file
addResourcePath("www", "../www")

# In your UI tagList
ui <- tagList(
  tags$head(tags$link(rel="stylesheet", type="text/css", href="www/shared-styles.css")),
  # ... rest of your UI
)
```

## Design System

The shared CSS implements a consistent design system with:

### Brand Colors
- **Primary Gradient**: #F9B397, #D68A93, #AD92B1, #B07891
- **Text**: #2c3e50 (dark gray)
- **Accent**: #d68a93 (brand pink)

### Components
- **Animated Navbar**: Gradient animation with consistent nav styling
- **Value Boxes**: Outlined style with brand color borders (red, orange, yellow, green)
- **Cards**: Clean design with subtle shadows and hover effects
- **Buttons**: Professional styling with gradient primary buttons
- **Tables**: Professional DataTables styling with consistent headers

### Features
- Fully responsive design
- Consistent typography
- Loading animations
- Drag and drop table styling
- Footer styling matching the brand

## Adding New Styles

When adding styles for new components:

1. Add component-specific styles to the appropriate section
2. Use the existing color variables and design patterns
3. Ensure mobile responsiveness
4. Test across all tools to ensure no conflicts

## Browser Support

The CSS is designed to work across modern browsers and includes fallbacks for older browsers where needed.