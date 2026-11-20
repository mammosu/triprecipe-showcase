# Custom Instructions for GitHub Copilot

## コーディング規約
- RuboCop Rails Omakaseを使用
- クラスベースのコンポーネント設計（ViewComponent）
- サービスオブジェクトパターンの使用（app/services/）
- RESTfulなコントローラデザイン

## テスト方針
- RSpecを使用したテスト駆動開発
- FactoryBotによるテストデータ生成
- SystemSpecによるE2Eテスト
- モデルのバリデーションと関連のテスト

## 実装のヒント
1. モデル間の関連は複雑なので、常にアソシエーションを確認する

## 注意点
1. Dockerコンテナ内での開発を前提に設定
2. コンポーネント名はBEMライクな命名規則を推奨
3. 関心の分離を意識する
4. レビューは日本語でコメントしてください。
5. 回答は日本語でお願いします。
