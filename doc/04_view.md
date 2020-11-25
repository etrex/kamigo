# View 的使用說明

在 view 當中，你可以根據不同的通訊平台，去製作對應的回覆內容。

Kamigo 會根據目前的平台，選擇對應的 render format，以 LINE 來說就會是 .line。

由於 Kamigo 目前只支援 LINE 通訊平台，因此目前只有 .line 可以使用。

舉例來說，如果你在 `config/routes.rb` 寫入以下程式：

```ruby
get "目錄", to: 'home#index'
```

而且你有 `app/controllers/home_controller` 內容如下：

```ruby
class HomeController < ApplicationController
end
```

即表示你應該要在 `app/views/home/index.line` 或者 `app/views/home/index.line.erb` 或者 `app/views/home/index.line.jbuilder` 來寫你的回覆訊息。

# 如何不回覆訊息

如果你不想回覆訊息的話，你可以建立一個空的 `app/views/home/index.line` 或 `app/views/home/index.line.erb` 或 `app/views/home/index.line.jbuilder` 來避免回覆訊息。

# 如何回覆訊息

你可以在 `app/views/home/index.line` 輸入以下訊息：

```ruby
{
  "type": "text",
  "text": "Hello, world"
}
```

或者你可以在 `app/views/home/index.line.erb` 輸入以下訊息：

```ruby
<%= raw {
  type: "text",
  text: "Hello, world"
}.to_json %>
```

或者你可以在 `app/views/home/index.line.jbuilder` 輸入以下訊息：

```ruby
json.type "text"
json.text "Hello, world"
```

最終都會產生出一樣的 json，也就是 [LINE Messaging API](https://developers.line.biz/en/reference/messaging-api/#text-message) 所要求的格式：

```ruby
{
  "type": "text",
  "text": "Hello, world"
}
```

# 使用 Flex Message

LINE Messaging API 提供了一種訊息格式，稱為 [Flex Message](https://developers.line.biz/en/docs/messaging-api/using-flex-messages/)。

你可以使用 [Kamiflex](https://github.com/etrex/kamiflex) 來快速生成 Flex Message。

目前在 view 當中使用 Kamiflex 的方法是使用 erb，比方說在 `app/views/home/index.line.erb` 輸入以下程式碼：

```
<%= raw(Kamiflex.build(self) do
  bubble do
    body do
      horizontal_box do
        text "Hello, world"
      end
    end
  end
end )%>
```

更多的 [Kamiflex 使用說明](https://github.com/etrex/kamiflex)

# 使用 LIFF
## 更換 LIFF Size
使用 `liff_path` 方法時，新增指定參數 `liff_size`：

```ruby
<%= liff_path(path: new_todo_path, liff_size: :compact) %>
<%= liff_path(path: new_todo_path, liff_size: :tall) %>
<%= liff_path(path: new_todo_path, liff_size: :full) %>
```
