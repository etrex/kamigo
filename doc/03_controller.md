# Controller 的使用說明

## 可以在 Controller 取得的重要參數

在 controller 當中你可以取得幾個重要的 params:

### platform_type

platform_type 表示目前的 Request 是來自於哪一個通訊軟體。

Kamigo 目前僅支援 LINE，因此 platform_type 的值會是 "line"。

你可以使用以下程式碼取得 platform_type:

```ruby
params[:platform_type]
```

### source_type

source_type 表示目前的 Request 是來自於那一種對話框，其可能的值為 "user"、"room"、"group"。

你可以使用以下程式碼取得 source_type:

```ruby
params[:source_type]
```

### source_group_id

source_group_id 表示目前 Request 是來自於哪一個對話框。

若 source_type 的值為 "user"，則 source_group_id 會與 LINE 提供的 userId 相等。

若 source_type 的值為 "room" 或 "group"，則 source_group_id 的值會等於 LINE 提供的 roomId 或 groupId。

你可以使用以下程式碼取得 source_group_id:

```ruby
params[:source_group_id]
```

### source_user_id

source_user_id 表示目前 Request 是來自於哪一個使用者。

source_user_id 會與 LINE 提供的 userId 相等。

在無法取得 userId 的某些情形下，source_user_id 的值將會與 source_group_id 相等。

你可以使用以下程式碼取得 source_user_id:

```ruby
params[:source_user_id]
```

## 身分驗證

你可以假設 source_group_id 以及 source_user_id 是秘密資訊，以 source_group_id 和 source_user_id 來識別對話框以及用戶。

## 在 Controller 回覆訊息

如果想要不回覆訊息的話：

```ruby
head :ok
```

```ruby
render json: {}
```

如果想要回覆訊息：

```ruby
render json: { type:'text', text:'hello kamigo' }
```

## 使用 Flex Message

LINE Messaging API 提供了一種訊息格式，稱為 [Flex Message](https://developers.line.biz/en/docs/messaging-api/using-flex-messages/)。

你可以使用 [Kamiflex](https://github.com/etrex/kamiflex) 來快速生成 Flex Message。

目前在 controller 當中使用 Kamiflex 的方法如下：

```
flex_message = Kamiflex.build(self) do
  bubble do
    body do
      text "Hello, world"
    end
  end
end
render json: flex_message
```

更多的 [Kamiflex 使用說明](https://github.com/etrex/kamiflex)
