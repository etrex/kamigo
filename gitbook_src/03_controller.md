# Controller 的使用說明

在 controller 當中你可以取得幾個重要的 params:

## platform_type

platform_type 表示目前的 Request 是來自於哪一個通訊軟體。

Kamigo 目前僅支援 LINE，因此 platform_type 的值會是 "line"。

你可以使用以下程式碼取得 platform_type:

```ruby
params[:platform_type]
```

## source_type

source_type 表示目前的 Request 是來自於那一種對話框，其可能的值為 "user"、"room"、"group"。

你可以使用以下程式碼取得 source_type:

```ruby
params.dig(:source_type)
```

## source_group_id

source_group_id 表示目前 Request 是來自於哪一個對話框。

若 source_type 的值為 "user"，則 source_group_id 會與 LINE 提供的 userId 相等。

若 source_type 的值為 "room" 或 "group"，則 source_group_id 的值會等於 LINE 提供的 roomId 或 groupId。

你可以使用以下程式碼取得 source_group_id:

```ruby
params.dig(:source_group_id)
```

## source_user_id

source_user_id 表示目前 Request 是來自於哪一個使用者。

source_user_id 會與 LINE 提供的 userId 相等。

在無法取得 userId 的某些情形下，source_user_id 的值將會與 source_group_id 相等。

你可以使用以下程式碼取得 source_user_id:

```ruby
params.dig(:source_user_id)
```

## message_type

message_type 表示目前 Request 的訊息類型。

message_type 與 LINE 提供的 message.type 相等。

在無法取得 message.type 的某些情形下，message_type 的值將會與 event.type 相等。

你可以使用以下程式碼取得 message_type:

```ruby
params.dig(:message_type)
```

## message

message_type 表示目前 Request 的訊息類型。

message_type 與 LINE 提供的 message.text, postback.data, message.address 相等。

在無法取得上述資訊的情形下，message 的值將會與 message_type 相等。

你可以使用以下程式碼取得 message:

```ruby
params.dig(:message)
```

## profile

profile 表示目前 Request 的用戶資訊。

profile 內包含以下資訊：

- displayName
- userId
- pictureUrl
- language (僅於私訊時可取得)
- statusMessage (僅於私訊時可取得)

你可以使用以下程式碼取得相關資訊:

```ruby
displayName = params.dig(:profile, :displayName)
userId = params.dig(:profile, :userId)
pictureUrl = params.dig(:profile, :pictureUrl)
language = params.dig(:profile, :language)
statusMessage = params.dig(:profile, :statusMessage)
```

## payload

payload 是 webhook 的原始資料，你可以在這裡取得 [LINE 的完整 webhook event object](https://developers.line.biz/en/reference/messaging-api/#webhook-event-objects)。

你可以使用以下程式碼取得 payload:

```ruby
payload = params.dig(:payload)
```


## 身分驗證

你可以假設 source_group_id 以及 source_user_id 是秘密資訊，以 source_group_id 和 source_user_id 來識別當前對話框以及用戶。