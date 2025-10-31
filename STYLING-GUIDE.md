# Modern Shiny App Styling Guide
## Making Your Apps Look Professional (Not Like Default Shiny)

Based on the Grant Research Assistant design, here's what makes it look polished and modern:

---

## 🎨 Key Design Elements

### 1. **Custom Font (Inter)**
```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap');

body {
  font-family: 'Inter', sans-serif;
}
```
**Why it works**: Inter is a modern, clean sans-serif designed for screens. Replaces default system fonts.

### 2. **Gradient Background**
```css
body {
  background: linear-gradient(135deg, #F9B397 0%, #D68A93 25%, #AD92B1 75%, #B07891 100%);
  min-height: 100vh;
  padding: 20px;
}
```
**Why it works**: Creates visual interest, brand consistency, makes the app feel premium.

### 3. **White Card Container**
```css
.main-container {
  background: white;
  border-radius: 16px;
  padding: 40px;
  max-width: 1400px;
  margin: 0 auto;
  box-shadow: 0 20px 60px rgba(0,0,0,0.15);
}
```
**Why it works**: Creates depth, focuses attention, feels like a modern web app (not a bare form).

### 4. **Rounded Corners Everywhere**
```css
border-radius: 8px;   /* For buttons, inputs, cards */
border-radius: 12px;  /* For larger sections */
border-radius: 16px;  /* For main container */
```
**Why it works**: Softens the UI, feels modern and approachable.

### 5. **Subtle Hover Effects**
```css
.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(0,0,0,0.2);
}
```
**Why it works**: Adds interactivity, confirms clickability, feels responsive.

### 6. **Gradient Buttons (Not Solid Colors)**
```css
.btn-primary {
  background: linear-gradient(135deg, #D68A93, #AD92B1);
  border: none;
  border-radius: 8px;
  padding: 10px 25px;
  font-weight: 600;
}
```
**Why it works**: More visually interesting than flat colors, on-brand.

### 7. **Light Gray Backgrounds for Sections**
```css
.filter-section {
  background: #f8f9fa;
  padding: 20px;
  border-radius: 12px;
  border: 1px solid #e0e0e0;
}
```
**Why it works**: Creates visual hierarchy without harsh borders.

### 8. **Colored Left Borders (Accent)**
```css
.info-box {
  background: linear-gradient(135deg, rgba(249, 179, 151, 0.1), rgba(214, 138, 147, 0.1));
  border-left: 4px solid #D68A93;
  padding: 15px;
  border-radius: 8px;
}
```
**Why it works**: Draws attention, adds brand color subtly, modern design pattern.

### 9. **Generous Spacing**
```css
padding: 40px;      /* Main container */
margin-bottom: 25px; /* Between sections */
padding: 15px;      /* Info boxes */
```
**Why it works**: Prevents cramped feeling, improves readability, feels premium.

### 10. **Typography Hierarchy**
```css
h1 {
  color: #333;
  font-weight: 700;
  font-size: 2.5em;
  margin-bottom: 10px;
}

.subtitle {
  color: #666;
  font-size: 1.1em;
  font-weight: 300;
}
```
**Why it works**: Clear hierarchy, professional weight usage, not all bold.

---

## 📦 Component Patterns

### Stat Cards
```css
.stat-card {
  background: linear-gradient(135deg, #F9B397, #D68A93);
  color: white;
  padding: 20px;
  border-radius: 12px;
  text-align: center;
  box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}
```

### Info Boxes
```css
.info-box {
  background: linear-gradient(135deg, rgba(249, 179, 151, 0.1), rgba(214, 138, 147, 0.1));
  border-left: 4px solid #D68A93;
  padding: 15px;
  border-radius: 8px;
  margin-bottom: 25px;
}
```

### Tabs
```css
.nav-pills > li.active > a {
  background: #D68A93;
  color: white;
  border-radius: 8px;
  font-weight: 600;
}

.nav-pills > li > a:hover {
  background: #B07891;
  color: white;
}
```

---

## 🚫 What to AVOID (Default Shiny Look)

### ❌ Don't Use:
- Default system fonts
- Flat gray backgrounds with no depth
- Sharp 90° corners everywhere
- Default blue Shiny buttons
- No spacing/padding
- Black text on white backgrounds only
- Default selectInput styling
- No hover states

### ✅ Instead Use:
- Custom web fonts (Inter, Poppins, etc.)
- Gradient backgrounds or textured backgrounds
- Border-radius on everything
- Gradient or brand-colored buttons
- Generous padding and margins
- Color hierarchy (#333 for headers, #666 for body)
- Custom styled inputs with rounded corners
- Subtle hover effects (transform, shadow)

---

## 🎯 Quick Implementation for Existing Apps

### Step 1: Add Font Import
```r
tags$head(
  tags$style(HTML("
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap');
  "))
)
```

### Step 2: Wrap UI in Container
```r
ui <- fluidPage(
  tags$style(HTML("
    body {
      background: linear-gradient(135deg, #F9B397 0%, #D68A93 25%, #AD92B1 75%, #B07891 100%);
      min-height: 100vh;
      padding: 20px;
      font-family: 'Inter', sans-serif;
    }
  ")),

  div(class = "main-container", style = "
    background: white;
    border-radius: 16px;
    padding: 40px;
    max-width: 1400px;
    margin: 0 auto;
    box-shadow: 0 20px 60px rgba(0,0,0,0.15);
  ",
    # Your existing UI content here
  )
)
```

### Step 3: Style Buttons
```r
tags$style(HTML("
  .btn-primary {
    background: linear-gradient(135deg, #D68A93, #AD92B1) !important;
    border: none !important;
    border-radius: 8px !important;
    padding: 10px 25px !important;
    font-weight: 600 !important;
    color: white !important;
    transition: transform 0.2s;
  }

  .btn-primary:hover {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(0,0,0,0.2);
  }
"))
```

### Step 4: Style Inputs
```r
tags$style(HTML("
  .form-control, .selectize-input {
    border-radius: 8px !important;
    border: 2px solid #e0e0e0 !important;
    padding: 10px !important;
  }

  .form-control:focus, .selectize-input.focus {
    border-color: #D68A93 !important;
    box-shadow: 0 0 0 0.2rem rgba(214, 138, 147, 0.25) !important;
  }
"))
```

### Step 5: Add Section Backgrounds
```r
div(style = "
  background: #f8f9fa;
  padding: 20px;
  border-radius: 12px;
  border: 1px solid #e0e0e0;
  margin-bottom: 25px;
",
  # Section content here
)
```

---

## 🎨 Brand Color Palette

```css
/* Primary Gradients */
#F9B397  /* Peach */
#D68A93  /* Rose */
#AD92B1  /* Lavender */
#B07891  /* Mauve */

/* Neutrals */
#333     /* Dark text (headers) */
#666     /* Body text */
#999     /* Muted text */
#f8f9fa  /* Light gray backgrounds */
#e0e0e0  /* Borders */

/* Dark Footer */
#2c3e50  /* Dark blue-gray */
#34495e  /* Lighter blue-gray */
```

---

## 📱 Responsive Considerations

```css
/* Mobile-friendly spacing */
@media (max-width: 768px) {
  .main-container {
    padding: 20px;
    border-radius: 8px;
  }

  body {
    padding: 10px;
  }
}
```

---

## 🚀 Full Template for Copy-Paste

See the Grant Research Assistant app.R lines 64-258 for the complete CSS implementation.

Key sections to copy:
1. Font import (line 65)
2. Body gradient background (lines 67-72)
3. Main container styling (lines 74-81)
4. Typography (lines 83-95)
5. Button styling (lines 134-146)
6. Tab styling (lines 188-207)
7. Footer styling (lines 157-186)

---

## 💡 Pro Tips

1. **Consistency is key**: Use the same border-radius values throughout (8px, 12px, 16px)
2. **Don't overdo gradients**: Use them strategically (background, buttons, stat cards)
3. **Shadow hierarchy**: Subtle shadows for depth (0 2px 8px), larger for elevation (0 20px 60px)
4. **Color restraint**: Stick to your brand colors + neutrals, don't add random colors
5. **Test on mobile**: Reduce padding/spacing for smaller screens
6. **Hover states**: Add them to all interactive elements
7. **Loading states**: Consider adding skeleton screens or spinners with matching colors

---

## 🔄 Migration Checklist

For Donor Retention Calculator and Board Packet Generator:

- [ ] Add Inter font import
- [ ] Add gradient background to body
- [ ] Wrap UI in white rounded card container
- [ ] Style all buttons with gradients
- [ ] Add border-radius to inputs and selects
- [ ] Create section backgrounds (#f8f9fa)
- [ ] Add hover effects to buttons
- [ ] Style tabs with brand colors
- [ ] Update footer styling
- [ ] Add info boxes with colored left borders
- [ ] Increase padding and margins
- [ ] Update typography hierarchy
- [ ] Test on mobile

---

This styling guide transforms default Shiny apps into modern, professional web applications that match the Grant Research Assistant's polished look.
