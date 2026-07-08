# GitHub Actions Setup Guide for Currency Caching

This guide explains how to initialize and configure the GitHub Actions workflow to automatically fetch and cache exchange rates for your Flutter app.

## 1. Prerequisites
- A GitHub account.
- The `smart_expenses_plan` repository pushed to GitHub.

## 2. Push the Workflow File
The workflow file has already been created locally at `.github/workflows/update_rates.yml`.
You must commit and push this file to your GitHub repository:
```bash
git add .github/workflows/update_rates.yml
git add lib/services/currency_service.dart
git add lib/presentation/screens/calculator/currency_converter.dart
git commit -m "feat: setup currency caching via github actions"
git push origin main
```

## 3. Enable GitHub Actions Permissions
By default, GitHub Actions might not have permission to push code back to your repository. You must enable "Read and write permissions" for the workflow to save the `rates.json` file.

1. Go to your repository on GitHub.
2. Click on **Settings**.
3. In the left sidebar, under **Code and automation**, click on **Actions** > **General**.
4. Scroll down to the **Workflow permissions** section.
5. Select **Read and write permissions**.
6. Click **Save**.

## 4. Trigger the First Run Manually
To ensure the `rates.json` file is created immediately without waiting for midnight UTC, trigger the workflow manually:

1. Go to your repository on GitHub.
2. Click on the **Actions** tab.
3. On the left sidebar, click on **Update Exchange Rates** (the name of our workflow).
4. On the right side, click the **Run workflow** dropdown button.
5. Select the `main` branch and click the green **Run workflow** button.
6. Wait for the action to complete. Once finished, you should see a new file named `rates.json` at the root of your repository.

## 5. Verification
- Open your Flutter app.
- Navigate to the Currency Converter.
- Ensure the app successfully fetches the latest exchange rates and allows you to select any of the 160+ currencies.
- If you turn off Wi-Fi/Data and open the app, it will fallback to the last fetched cache on your device.
