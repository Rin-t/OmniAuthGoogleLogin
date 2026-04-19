# README
練習用リポジトリ
## Rails
- OmniAuthでGoogleLoginできるように
- GoogleLoginのstatusをテーブル管理して、GoogleLoginからのcallbackが帰ってきた時に同一ユーザーかを判定する仕組み
- Doorkeeperで認可周りを実装し、iOSアプリにアクセストークンを渡す

## iOS
- GoogleLoginSample配下にある
- ASWebAuthenticationSessionを使ってGoogleLoginをする
- webアプリケーションから認可コードを受け取ってdoorkeeperからのアクセストークンを受け取る
