# Dual Deployment Setup Guide

This project supports two deployment modes:

1. **Public Portfolio** (GitHub Pages + Shinylive) - No authentication
2. **Private Client Access** (Shinyapps.io) - Auth0 authentication

## 🔧 Setup Instructions

### 1. Auth0 Configuration

1. Create an Auth0 application at https://manage.auth0.com/
2. Configure your Auth0 app:
   - **Application Type**: Regular Web Application
   - **Allowed Callback URLs**: 
     - `https://YOUR_ACCOUNT.shinyapps.io/donor-retention-private/`
     - `https://YOUR_ACCOUNT.shinyapps.io/board-packet-private/`
   - **Allowed Logout URLs**: 
     - `https://YOUR_ACCOUNT.shinyapps.io/donor-retention-private/`
     - `https://YOUR_ACCOUNT.shinyapps.io/board-packet-private/`
   - **Allowed Web Origins**: `https://YOUR_ACCOUNT.shinyapps.io`

### 2. Shinyapps.io Setup

1. Create account at https://www.shinyapps.io/
2. Get your deployment tokens:
   - Go to Account > Tokens
   - Copy your account name, token, and secret

### 3. GitHub Secrets Configuration

Add these secrets to your GitHub repository (Settings > Secrets and variables > Actions):

#### Required Secrets:
```
SHINYAPPS_ACCOUNT=your-shinyapps-account-name
SHINYAPPS_TOKEN=your-shinyapps-token
SHINYAPPS_SECRET=your-shinyapps-secret

AUTH0_DOMAIN=your-auth0-domain.auth0.com
AUTH0_CLIENT_ID=your-auth0-client-id
AUTH0_CLIENT_SECRET=your-auth0-client-secret
```

### 4. Local Development with Auth0

1. Copy the auth0 template:
   ```bash
   cp donor-retention-calculator/_auth0.yml.template donor-retention-calculator/_auth0.yml
   ```

2. Edit `_auth0.yml` with your Auth0 credentials:
   ```yaml
   name: donor-retention-local
   remote_url: 'http://localhost:8100/'
   auth0_config:
     api_url: https://your-domain.auth0.com
     credentials:
       key: your-client-id
       secret: your-client-secret
   ```

3. Update Auth0 app to allow localhost:
   - Add `http://localhost:8100/` to Allowed Callback URLs
   - Add `http://localhost:8100/` to Allowed Logout URLs
   - Add `http://localhost:8100/` to Allowed Web Origins

## 🚀 Deployment

### Automatic Deployment

Both deployments happen automatically:

- **GitHub Pages (Public)**: Triggers on push to `main` via existing workflow
- **Shinyapps.io (Private)**: Triggers on push to `main` when app files change

### Manual Deployment

You can manually deploy to Shinyapps.io:

1. Go to Actions tab in GitHub
2. Select "Deploy to Shinyapps.io" workflow  
3. Click "Run workflow"
4. Choose which app to deploy

## 🔗 Access URLs

After deployment, your apps will be available at:

- **Public Portfolio**: 
  - Donor Retention: `https://yourusername.github.io/nonprofit-analytics-tools/donor-retention-calculator/`
  - Board Packet: `https://yourusername.github.io/nonprofit-analytics-tools/board-packet-generator/`

- **Private Client Access**:
  - Donor Retention: `https://your-account.shinyapps.io/donor-retention-private/`
  - Board Packet: `https://your-account.shinyapps.io/board-packet-private/`

## 🔍 How It Works

The apps automatically detect their environment:

- **Shinylive**: Runs in public mode (no auth)
- **Shinyapps.io**: Loads Auth0 if config file present
- **Local**: Uses Auth0 if `_auth0.yml` exists

## 📁 File Structure

```
nonprofit-analytics-tools/
├── .github/workflows/
│   ├── deploy-shinylive.yml      # Public deployment
│   └── deploy-shinyapps.yml      # Private deployment
├── donor-retention-calculator/
│   ├── app.R                     # Main app with conditional auth
│   └── _auth0.yml.template       # Auth0 config template
├── board-packet-generator/
│   └── app.R                     # Board packet app
└── DEPLOYMENT.md                 # This guide
```

## 🔒 Security Notes

- Auth0 config files are never committed to git
- Secrets are only available during GitHub Actions
- Local `_auth0.yml` should be in `.gitignore`
- Private apps require Auth0 login to access

## 🐛 Troubleshooting

### App won't load on Shinyapps.io
- Check that all required secrets are set
- Verify Auth0 callback URLs match deployment URL
- Check deployment logs in GitHub Actions

### Auth0 not working locally
- Ensure `_auth0.yml` exists and has correct credentials
- Verify localhost is added to Auth0 allowed URLs
- Check that auth0 R package is installed

### Public version showing auth errors
- The app should auto-detect Shinylive and skip auth
- If not, check the environment detection logic