# 點擊事件
Action 可以為 [基礎組件](/kamiflex/basic_element.md) 或部分的 [基礎組件](/kamiflex/basic_element.md) 新增點擊事件。
## Message Action
#### 說明
Message Action 是一個點擊後會傳送文字的 Action，關於 Action 的說明請參考官方文件中的 [LINE Flex Message 關於 Action 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#action-objects)。

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- label (必填)
- text

    點擊後會傳送的文字，預設與 label 一樣

#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

無

#### 使用範例
Ruby 寫法：
```ruby
json = Kamiflex.json(self) do
  bubble do
    body do
      text "這是文字方塊，但你點點看", action: message_action("就算是文字方塊，照樣可以觸發 Action")
    end
  end
end

puts json
```
對應的 JSON：
```json
{
  "type": "flex",
  "altText": "this is a flex message",
  "contents": {
    "type": "bubble",
    "body": {
      "type": "box",
      "layout": "vertical",
      "contents": [
        {
          "type": "text",
          "text": "這是文字方塊，但你點點看",
          "action": {
            "type": "message",
            "label": "就算是文字方塊，照樣可以觸發 Action",
            "text": "就算是文字方塊，照樣可以觸發 Action"
          }
        }
      ]
    }
  }
}
```

## URI Action
#### 說明
URI Action 是一個點擊後會開啟指定網頁的 Action，關於 Action 的說明請參考官方文件中的 [LINE Flex Message 關於 Action 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#action-objects)。

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- url (必填)
- label
- altUri.desktop

#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

無

#### 使用範例
Ruby 寫法：
```ruby
json = Kamiflex.json(self) do
  bubble do
    body do
      text "這是文字方塊，但你點點看", action: uri_action("https://www.kamigo.tw/")
    end
  end
end

puts json
```
對應的 JSON：
```json
{
  "type": "flex",
  "altText": "this is a flex message",
  "contents": {
    "type": "bubble",
    "body": {
      "type": "box",
      "layout": "vertical",
      "contents": [
        {
          "type": "text",
          "text": "這是文字方塊，但你點點看",
          "action": {
            "type": "uri",
            "label": "https://www.kamigo.tw/",
            "uri": "https://www.kamigo.tw/"
          }
        }
      ]
    }
  }
}
```

## Postback Action
#### 說明
Postback Action 是一個點擊後會傳送資料(使用者看不到)的 Action，關於 Action 的說明請參考官方文件中的 [LINE Flex Message 關於 Action 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#action-objects)。

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- data (必填)

    點擊按鈕會傳送的資料
- label
- displayText
- text

    點擊按鈕會傳送的文字

#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

無

#### 使用範例
Ruby 寫法：
```ruby
json = Kamiflex.json(self) do
  bubble do
    body do
      text "這是文字方塊，但你點點看", action: postback_action("這是機密資料你看不到", text: "這是文字訊息你看得到")
    end
  end
end

puts json
```
對應的 JSON：
```json
{
  "type": "flex",
  "altText": "this is a flex message",
  "contents": {
    "type": "bubble",
    "body": {
      "type": "box",
      "layout": "vertical",
      "contents": [
        {
          "type": "text",
          "text": "這是文字方塊，但你點點看",
          "action": {
            "type": "postback",
            "data": "這是機密資料你看不到",
            "text": "這是文字訊息你看得到"
          }
        }
      ]
    }
  }
}
```