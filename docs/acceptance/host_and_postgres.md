# Rails 宿主與 PostgreSQL 可靠性驗收

日期：2026-09-10。

`script/acceptance/host_install.rb` 以公開 Rails/Kamigo 指令建立全新、無 asset pipeline 的 Rails 8.1 暫存專案，執行 `kamigo:install`、六個 migration，並由真實宿主 boot 確認 Engine、principal、conversation、receipt 與 initializer 都存在。第一次操作因此發現 Kamiliff initializer 錯誤假設 asset pipeline 必定存在；修正 guard 後相同流程成功。`test/v1/host_install_test.rb` 重現同一流程。

`script/acceptance/postgres_reliability.rb` 建立 Unix socket 限定的一次性 PostgreSQL 15。兩個 thread 同時接收相同平台事件，實測一個 receipt、一個業務效果及一個 outbox；兩個 thread 再同時外送該 outbox，平台 adapter只被呼叫一次且狀態為sent。同一腳本再讓第一則 Telegram 訊息停在實際送出中，競爭 worker 嘗試同 conversation 的第二則時必須得到 `blocked`；第一則完成後重試第二則，平台觀察順序必須是 `first, second`。接著刻意讓較小 ID 的同對話 enqueue 保持未 commit，並以 `pg_locks` 與 `pg_blocking_pids` 直接觀察第二個 backend 正在等待第一個 transaction advisory lock；平台最後仍依 `race first, race second` 收件。過期 pending 以 1,000／1,000／501 三個有界批次清除並逐次推進 head，stale sending 轉 uncertain 後也會推進。最後在單一阻塞 stream 寫入 1,000,000 筆 pending，另一段對話仍立即成為 ready；`EXPLAIN ANALYZE` 使用 `kamigo_outbox_ready_heads` partial index，本機 execution time 為 0.008 ms。`test/v1/postgres_reliability_acceptance_test.rb` 重現同一公開可靠性流程。所有暫存資料庫和宿主在結束時清除，不讀既有 DATABASE_URL。
## PostgreSQL 完整宿主安裝

`script/acceptance/postgres_host_install.rb` 會建立全新的 Rails 8.1 宿主與一次性 PostgreSQL 15 cluster，執行公開的 `kamigo:install` generator，依序套用 generator 複製出的六支 migration，再由宿主 boot Kamigo models。公開驗收會建立 principal、external identity、conversation、membership、receipt 與 outbox，並直接確認 PostgreSQL 拒絕非法 membership role、空 identity，以及 terminal row 保留 stream head。這補足 SQLite 宿主安裝無法證明 PostgreSQL collation、foreign key、partial index 與 check constraint 的範圍。

2026-09-10 agent 先人工執行上述腳本，觀察 `adapter=PostgreSQL`、六張表與六類模型寫入全為 true、三項非法資料全遭 constraint 拒絕、七個 stream／ready／maintenance partial index 全存在、initializer 已載入、migration 數為 6。其後 `test/v1/postgres_host_install_test.rb` 逐欄重現同一支公開腳本與相同預期結果。
