# 基礎組件
基礎組件需被包含在 [容器元件](/kamiflex/container.md) 或是 [header](/kamiflex/core.md#header)、[body](/kamiflex/core.md#body) 或 [footer](/kamiflex/core.md#footer) 的 `do ... end` 之中。
## Text
#### 說明
Text 是用來放置文字的元件，關於 Text 的說明請參考官方文件中的 [LINE Flex Message 關於 Text 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#f-text)。

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- message (必填)
- adjustMode
- flex
- margin
- position
- offsetTop
- offsetBottom
- offsetStart
- offsetEnd
- size
- align
- gravity
- wrap
- maxLines
- weight
- color
- [action](/kamiflex/action.md)
- style
- decoration

#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

無

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.json(self) do
  bubble do
    body do
      text "Hello, World!", color:"#ff0000"
    end
  end
end
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
          "text": "Hello, World!",
          "color": "#ff0000"
        }
      ]
    }
  }
}
```

## Image
#### 說明
Image 是用來放置圖片的元件，關於 Image 的說明請參考官方文件中的 [LINE Flex Message 關於 Image 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#f-image)。

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- url (必填)
- flex
- margin
- position
- offsetTop
- offsetBottom
- offsetStart
- offsetEnd
- align
- gravity
- size
- aspectRatio
- aspectMode
- backgroundColor
- [action](/kamiflex/action.md)
- animated

#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

無

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.json(self) do
  bubble do
    body do
      image "https://www.kamigo.tw/assets/kamigo-c3b10dff4cdb60fa447496b22edad6c32fffde96de20262efba690892e4461e8.png"
    end
  end
end
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
          "type": "image",
          "url": "https://www.kamigo.tw/assets/kamigo-c3b10dff4cdb60fa447496b22edad6c32fffde96de20262efba690892e4461e8.png"
        }
      ]
    }
  }
}
```

## Icon
#### 說明
Icon 僅能放置在 [baseline_box](/kamiflex/container.md#baseline_box) 中，關於 Icon 的說明請參考官方文件中的 [LINE Flex Message 關於 Icon 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#icon)。

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- url (必填)
- margin
- position
- offsetTop
- offsetBottom
- offsetStart
- offsetEnd
- size
- aspectRatio


#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

無

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.json(self) do
  bubble do
    body layout: "baseline" do
      icon "https://www.kamigo.tw/assets/kamigo-c3b10dff4cdb60fa447496b22edad6c32fffde96de20262efba690892e4461e8.png"
      text "這是卡米狗哦", offsetStart: "20px"
    end
  end
end
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
      "layout": "baseline",
      "contents": [
        {
          "type": "icon",
          "url": "https://www.kamigo.tw/assets/kamigo-c3b10dff4cdb60fa447496b22edad6c32fffde96de20262efba690892e4461e8.png"
        },
        {
          "type": "text",
          "text": "這是卡米狗哦",
          "offsetStart": "20px"
        }
      ]
    }
  }
}
```

## Separator
#### 說明
Separator 是一個分隔線元件，關於 Separator 的說明請參考官方文件中的 [LINE Flex Message 關於 Separator 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#separator)。

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- margin
- color


#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

無

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.json(self) do
  bubble do
    body do
      text "牛郎"
      separator
      text "織女"
    end
  end
end
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
          "text": "牛郎"
        },
        {
          "type": "separator",
          "margin": "md",
          "color": "#000000"
        },
        {
          "type": "text",
          "text": "織女"
        }
      ]
    }
  }
}
```

## Filler
#### 說明
Filler 是一個空白元件，關於 Filler 的說明請參考官方文件中的 [LINE Flex Message 關於 Filler 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#filler)。

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- flex


#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

無

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.json(self) do
  bubble do
    body do
      text "Hello"
      filler
      text "World"
    end
  end
end
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
          "text": "Hello"
        },
        {
          "type": "filler"
        },
        {
          "type": "text",
          "text": "World"
        }
      ]
    }
  }
}
```

## Message Button
#### 說明
Message Button 是點擊後會傳送文字的 Button，關於 Button 的說明請參考官方文件中的 [LINE Flex Message 關於 Button 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#button)。

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- label (必填)

  按鈕上的文字
- message (必填)

  點擊按鈕會傳送的文字
- flex
- margin
- position
- offsetTop
- offsetBottom
- offsetStart
- offsetEnd
- height
- style
- color
- gravity
- adjustMode


#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

無

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.json(self) do
  bubble do
    body do
      message_button "這是一個 Message Button", "傳送的文字", style: "primary"
    end
  end
end
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
          "type": "button",
          "action": {
            "type": "message",
            "label": "這是一個 Message Button",
            "text": "傳送的文字"
          },
          "style": "primary"
        }
      ]
    }
  }
}
```

## URL Button
#### 說明
URL Button 是點擊後會開啟指定網頁的 Button，關於 Button 的說明請參考官方文件中的 [LINE Flex Message 關於 Button 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#button)。

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- label (必填)

  按鈕上的文字
- url (必填)

  點擊按鈕會開啟的網址
- flex
- margin
- position
- offsetTop
- offsetBottom
- offsetStart
- offsetEnd
- height
- style
- color
- gravity
- adjustMode


#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

無

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.json(self) do
  bubble do
    body do
      url_button "這是一個 URL Button", "https://www.kamigo.tw/", style: "primary"
    end
  end
end
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
          "type": "button",
          "action": {
            "type": "uri",
            "label": "這是一個 URL Button",
            "uri": "https://www.kamigo.tw/"
          },
          "style": "primary"
        }
      ]
    }
  }
}
```

## Postback Button
#### 說明
Postback Button 是點擊後會傳送特定資料(使用者看不到)的 Button，關於 Button 的說明請參考官方文件中的 [LINE Flex Message 關於 Button 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#button)。

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- label (必填)

  按鈕上的文字
- data (必填)

  點擊按鈕會傳送的資料
- flex
- margin
- position
- offsetTop
- offsetBottom
- offsetStart
- offsetEnd
- height
- style
- color
- gravity
- adjustMode


#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

無

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.json(self) do
  bubble do
    body do
      postback_button "這是一個 Postback Button", "這是機密資料你看不到", style: "primary"
    end
  end
end
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
          "type": "button",
          "action": {
            "type": "postback",
            "label": "這是一個 Postback Button",
            "data": "這是機密資料你看不到"
          },
          "style": "primary"
        }
      ]
    }
  }
}
```

## Postback Text Button
#### 說明
Postback Text Button 是點擊後會傳送特定資料(使用者看不到)和傳送文字的 Button，關於 Button 的說明請參考官方文件中的 [LINE Flex Message 關於 Button 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#button)。

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- label (必填)

  按鈕上的文字
- message (必填)

  點擊按鈕會傳送的文字
- data (必填)

  點擊按鈕會傳送的資料
- flex
- margin
- position
- offsetTop
- offsetBottom
- offsetStart
- offsetEnd
- height
- style
- color
- gravity
- adjustMode


#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

無

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.json(self) do
  bubble do
    body flex: 10 do
      postback_text_button "這是 Postback Text Button", "這是文字訊息你看得到", "這是機密資料你看不到", style: "primary"
    end
  end
end
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
          "type": "button",
          "action": {
            "type": "postback",
            "label": "這是 Postback Text Button",
            "displayText": "這是文字訊息你看得到",
            "data": "這是機密資料你看不到"
          },
          "style": "primary"
        }
      ],
      "flex": 10
    }
  }
}
```