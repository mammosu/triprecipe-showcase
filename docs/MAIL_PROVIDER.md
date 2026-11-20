# メールプロバイダ設定 (SendGrid / Mailgun 切替)

このドキュメントは、TripRecipe のメール送信プロバイダの切替方法（SendGrid ↔ Mailgun）と必要な環境変数についてまとめたものです。

概要
- `config/initializers/mailer_provider.rb` によって `MAIL_PROVIDER` 環境変数でプロバイダを切り替えます。
- 対応: `sendgrid` (デフォルト)、`mailgun`、`test`。

必要な環境変数

```
# 選択: sendgrid または mailgun
MAIL_PROVIDER=mailgun

# 共通
MAILER_FROM=no-reply@triprecipe.app
MAIL_DOMAIN=triprecipe.app

# SendGrid (既存)
SENDGRID_API_KEY=SG.xxxxx

# Mailgun (SMTP 認証情報)
MAILGUN_SMTP_SERVER=smtp.mailgun.org    # 地域によって変わる場合あり
MAILGUN_SMTP_PORT=587
MAILGUN_SMTP_LOGIN=postmaster@your-domain
MAILGUN_SMTP_PASSWORD=your-mailgun-smtp-password
```

Fly での設定例

```bash
fly secrets set MAIL_PROVIDER=mailgun \
  MAILGUN_SMTP_LOGIN=postmaster@your-domain \
  MAILGUN_SMTP_PASSWORD=your-mailgun-smtp-password \
  MAIL_DOMAIN=triprecipe.app MAILER_FROM=no-reply@triprecipe.app
```

ステージングでの検証手順
1. ステージング環境に Mailgun の認証情報を設定する。
2. `MAIL_PROVIDER=mailgun` にしてアプリをデプロイし、招待メール等を送信して到達を確認する。
3. Mailgun 管理画面でイベント（accepted/delivered/bounce）を確認する。
4. 送信ドメインの SPF/DKIM を Mailgun 指示に従って設定する。

運用上の注意
- 不要になった `SENDGRID_API_KEY` はローテーションして削除することを推奨します。
- SMTP で十分であれば追加の gem は不要。Mailgun の HTTP API 機能が必要な場合は `mailgun-ruby` を導入検討してください。
