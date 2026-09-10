# HTTP-LOCAL-001

2026-09-09：先透過主服務實際瀏覽器驗收 LINE/TG signed event → durable outbox worker → 外部 loopback HTTP 收件。再直接執行套件公開 HttpTransport，以合成 Telegram token 向同一外部 HTTP simulator 發送 HTTP acceptance，回傳 status 200/message_id 3；遠端 http://example.test 作 local override 被 ArgumentError 拒絕。

後補 test/v1/http_transport_loopback_test.rb，使用實際 TCP HTTP server 回應，不替換 Net::HTTP client。另保留既有 timeout/rejection/size 等單元測試。此項只證明 HTTP 契約，不冒稱真實 Telegram/LINE 平台驗收。

local_http_endpoint 只能明確指定 http://127.0.0.1:port origin，不接受帳密、query、fragment、路徑或其他 host。產品整合另限制只能 development/test 使用；production 預設固定官方 HTTPS，不讀任意環境 proxy。

2026-09-10 的 GROUP-LEAVE-001 先由主服務手動走完「管理者在群組說卡米狗再見 → 回覆告別 → worker 呼叫離群 → 原成員登入後不再看到群組」。套件回歸以相同外送邊界補上 LINE group leave 與 Telegram leaveChat 的真實 loopback HTTP 驗收，核對官方路徑、認證 header、空 LINE body、Telegram chat_id 及 provider acceptance；adapter 單元測試另拒絕帶訊息、帶 reply token、錯誤 action 與無效 chat ID。
