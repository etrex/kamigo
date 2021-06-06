# 核心元件
核心元件需被寫在 Flex Message Meta 的 `do ... end` 之中。
## bubble
#### 說明
此元件為 Flex Message 最基礎之核心元件。
![](https://developers.line.biz/assets/img/overviewSample.772a618f.png) <br/>
詳細說明請參考以下連結：<br/>
[LINE Flex Message 關於 Bubble 的說明文件](https://developers.line.biz/en/docs/messaging-api/flex-message-elements/#bubble) <br/>
[LINE Flex Message 關於 Bubble 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#bubble)

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- size

  可以指定以下其中一個值： `nano`，`micro`，`kilo`，`mega` 或 `giga`。預設為 `mega`。

- direction

  可以指定以下其中一個值： `ltr` 或 `rtl`。預設為 `ltr` 。

- [action](/kamiflex/action.md)

#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

- [header](#header)
- [hero](#hero)
- [body](#body)
- [footer](#footer)
- [styles](#styles)

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.build(self) do
  bubble size: "nano",direction: "ltr" do
    body do
      text "Hello, World!"
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
          "text": "Hello, World!"
        }
      ]
    },
    "size": "nano",
    "direction": "ltr"
  }
}
```

## bubbles
#### 說明
此元件需使用在 `carousel` 之中，達成橫向多筆 Flex Message，若不使用此核心元件，亦可使用 Ruby 原生的 `#each` 搭配 `bubble` 達到相同功能。
#### 可用的引數
[說明](/05_kamiflex.md#引數)

- size

  可以指定以下其中一個值： `nano`，`micro`，`kilo`，`mega` 或 `giga`。預設為 `mega`。

- direction

  可以指定以下其中一個值： `ltr` 或 `rtl`。預設為 `ltr` 。

- [action](/kamiflex/action.md)

#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

- [header](#header)
- [hero](#hero)
- [body](#body)
- [footer](#footer)
- [styles](#styles)

#### 使用範例
使用 `bubbles` 的 Ruby 寫法：
```ruby
strings = ["Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.","Hello, World!"]
Kamiflex.hash(self) do
  carousel do
  bubbles strings do |string|
    body layout: "horizontal" do
      text string,wrap: true
    end
    footer layout: "horizontal" do
      url_button "Go","https://example.com",style: "primary"
    end
  end
  end
end
```
不使用 `bubbles` 的 Ruby 寫法：
```ruby
strings = ["Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.","Hello, World!"]
Kamiflex.hash(self) do
  carousel do
    strings.each do |string|
      bubble do
        body layout: "horizontal" do
          text string,wrap: true
        end
        footer layout: "horizontal" do
          url_button "Go","https://example.com",style: "primary"
        end
      end
    end
  end
end
```
對應的 Json：
```json
{
  "type": "flex",
  "altText": "this is a flex message",
  "contents": {
    "type": "carousel",
    "contents": [
      {
        "type": "bubble",
        "body": {
          "type": "box",
          "layout": "horizontal",
          "contents": [
            {
              "type": "text",
              "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
              "wrap": true
            }
          ]
        },
        "footer": {
          "type": "box",
          "layout": "horizontal",
          "contents": [
            {
              "type": "button",
              "action": {
                "type": "uri",
                "label": "Go",
                "uri": "https://example.com"
              },
              "style": "primary"
            }
          ]
        }
      },
      {
        "type": "bubble",
        "body": {
          "type": "box",
          "layout": "horizontal",
          "contents": [
            {
              "type": "text",
              "text": "Hello, World!",
              "wrap": true
            }
          ]
        },
        "footer": {
          "type": "box",
          "layout": "horizontal",
          "contents": [
            {
              "type": "button",
              "action": {
                "type": "uri",
                "label": "Go",
                "uri": "https://example.com"
              },
              "style": "primary"
            }
          ]
        }
      }
    ]
  }
}
```

## carousel
#### 說明
此元件可以達成橫向多筆的 Flex Message，但在其之中還需要加上 bubble 元件。
![](https://developers.line.biz/assets/img/carouselSample.b7d44737.png)<br>
[LINE Flex Message 關於 Carousel 的說明文件](https://developers.line.biz/en/docs/messaging-api/flex-message-elements/#carousel) <br/>
[LINE Flex Message 關於 Carousel 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#f-carousel)
#### 可用的引數
[說明](/05_kamiflex.md#引數)

無

#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

- [bubble](#bubble)
- [bubbles](#bubbles)
  
> 最多12個 bubble

#### 使用範例
使用 `bubbles` 的 Ruby 寫法：
```ruby
strings = ["Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.","Hello, World!"]
Kamiflex.hash(self) do
  carousel do
  bubbles strings do |string|
    body layout: "horizontal" do
      text string,wrap: true
    end
    footer layout: "horizontal" do
      url_button "Go","https://example.com",style: "primary"
    end
  end
  end
end
```
不使用 `bubbles` 的 Ruby 寫法：
```ruby
strings = ["Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.","Hello, World!"]
Kamiflex.hash(self) do
  carousel do
    strings.each do |string|
      bubble do
        body layout: "horizontal" do
          text string,wrap: true
        end
        footer layout: "horizontal" do
          url_button "Go","https://example.com",style: "primary"
        end
      end
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
    "type": "carousel",
    "contents": [
      {
        "type": "bubble",
        "body": {
          "type": "box",
          "layout": "horizontal",
          "contents": [
            {
              "type": "text",
              "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
              "wrap": true
            }
          ]
        },
        "footer": {
          "type": "box",
          "layout": "horizontal",
          "contents": [
            {
              "type": "button",
              "action": {
                "type": "uri",
                "label": "Go",
                "uri": "https://example.com"
              },
              "style": "primary"
            }
          ]
        }
      },
      {
        "type": "bubble",
        "body": {
          "type": "box",
          "layout": "horizontal",
          "contents": [
            {
              "type": "text",
              "text": "Hello, World!",
              "wrap": true
            }
          ]
        },
        "footer": {
          "type": "box",
          "layout": "horizontal",
          "contents": [
            {
              "type": "button",
              "action": {
                "type": "uri",
                "label": "Go",
                "uri": "https://example.com"
              },
              "style": "primary"
            }
          ]
        }
      }
    ]
  }
}
```

## header
#### 說明
需放置在 [bubble](#bubble) 或是 [bubbles](#bubbles) 的 `do ... end` 之中。呈現在 Flex Message 的最頂部，一般用來放置標題使用。

Kamflex 會為 header 自動創立一個容器元件 box，關於容器元件 box 引數請參考官方文件中的 [LINE Flex Message 關於 BOX 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#box)。
> 此處無法直接修飾 header 的 style，若想修飾 header 的 style 請使用 [styles](#styles)

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- layout
- backgroundColor
- borderColor
- borderWidth
- cornerRadius
- width
- height
- flex
- spacing
- margin
- paddingAll
- paddingTop
- paddingBottom
- paddingStart
- paddingEnd
- position
- offsetTop
- offsetBottom
- offsetStart
- offsetEnd
- [action](/kamiflex/action.md)
- justifyContent
- alignItems
- background.type
- background.angle
- background.startColor
- background.endColor
- background.centerColor
- background.centerPosition


#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

- [容器元件](/kamiflex/container.md)
- [基礎組件](/kamiflex/basic_element.md)

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.build(self) do
  bubble do
    header layout: "vertical", borderWidth: "light", backgroundColor: "#c3c3c3" do
      text "hello, wrold!"
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
    "header": {
      "type": "box",
      "layout": "vertical",
      "contents": [
        {
          "type": "text",
          "text": "hello, wrold!"
        }
      ],
      "borderWidth": "light",
      "backgroundColor": "#c3c3c3"
    }
  }
}

```

## hero
#### 說明
需放置在 [bubble](#bubble) 或是 [bubbles](#bubbles) 的 `do ... end` 之中。呈現在Flex Message [header](#header) 之下，[body](#body) 之上，一般用來放置圖片，**由於不需要搭配block。後方不需再加入`{...}`或是`do...end`**。

kamiflex 預設 hero 的 type 為 Image 元件，相關引述請搭配 [LINE Flex Message 關於 Image 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#f-image)。
> 此處無法直接修飾 hero 的 style，若想修飾 hero 的 style 請使用 [styles](#styles)
> hero 的 type 除了 image 元件外，也可以選擇為 box 元件

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- image_url (必填)
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
- animated
- [action](/kamiflex/action.md)

#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

無
#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.build(self) do
    bubble do
        hero "https://scdn.line-apps.com/n/channel_devcenter/img/fx/01_1_cafe.png",
size: :full, aspectRatio: "20:13"
    end
end
```
對應的 JSON:
```json
{
  "type": "flex",
  "altText": "this is a flex message",
  "contents": {
    "type": "bubble",
    "hero": {
      "type": "image",
      "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/01_1_cafe.png",
      "size": "full",
      "aspectRatio": "20:13"
    }
  }
}

```

### body
#### 說明
需放置在 [bubble](#bubble) 或是 [bubbles](#bubbles) 的 `do ... end` 之中。呈現在 Flex Message 中間的位置，一般用於表達內文。

Kamflex 會為 body 自動創立一個容器元件 box，關於容器元件 box 引數請參考官方文件中的 [LINE Flex Message 關於 BOX 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#box)
> 此處無法直接修飾 body 的 style，若想修飾 body 的 style 請使用 [styles](#styles)

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- layout
- backgroundColor
- borderColor
- borderWidth
- cornerRadius
- width
- height
- flex
- spacing
- margin
- paddingAll
- paddingTop
- paddingBottom
- paddingStart
- paddingEnd
- position
- offsetTop
- offsetBottom
- offsetStart
- offsetEnd
- [action](/kamiflex/action.md)
- justifyContent
- alignItems
- background.type
- background.angle
- background.startColor
- background.endColor
- background.centerColor
- background.centerPosition


#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

- [容器元件](/kamiflex/container.md)
- [基礎組件](/kamiflex/basic_element.md)

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.build(self) do
  bubble do
    body layout: "vertical", borderWidth: "light", backgroundColor: "#c3c3c3" do
      text "hello, wrold!"
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
          "text": "hello, wrold!"
        }
      ],
      "borderWidth": "light",
      "backgroundColor": "#c3c3c3"
    }
  }
}

```

### footer
#### 說明
需放置在 [bubble](#bubble) 或是 [bubbles](#bubbles) 的 `do ... end` 之中。呈現在 Flex Message 中間的位置，一般用於放置按鈕。

Kamflex 會為 footer 自動創立一個容器元件 box，關於容器元件 box 引數請參考官方文件中的 [LINE Flex Message 關於 BOX 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#box)
> 此處無法直接修飾 footer 的 style，若想修飾 footer 的 style 請使用 [styles](#styles)

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- layout
- backgroundColor
- borderColor
- borderWidth
- cornerRadius
- width
- height
- flex
- spacing
- margin
- paddingAll
- paddingTop
- paddingBottom
- paddingStart
- paddingEnd
- position
- offsetTop
- offsetBottom
- offsetStart
- offsetEnd
- [action](/kamiflex/action.md)
- justifyContent
- alignItems
- background.type
- background.angle
- background.startColor
- background.endColor
- background.centerColor
- background.centerPosition


#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

- [容器元件](/kamiflex/container.md)
- [基礎組件](/kamiflex/basic_element.md)

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.build(self) do
  bubble do
    footer layout: "vertical", borderWidth: "light", backgroundColor: "#c3c3c3" do
      text "hello, wrold!"
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
    "footer": {
      "type": "box",
      "layout": "vertical",
      "contents": [
        {
          "type": "text",
          "text": "hello, wrold!"
        }
      ],
      "borderWidth": "light",
      "backgroundColor": "#c3c3c3"
    }
  }
}
```
    
### styles
#### 說明
主要功能為修飾 [header](#header)、[hero](#hero)、[body](#body)、[footer](#footer) 的style。
請參考官方文件中的 [LINE Flex Message 關於 Block Style 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#block-style)。

#### 可用的引數
[說明](/05_kamiflex.md#引數)

僅接受一個 Hash，

#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

無

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.build(self) do
  bubble size: "mega" do
    header do
      text "Kamiflex"
    end
    hero "https://stickershop.line-scdn.net/stickershop/v1/product/1500785/LINEStorePC/main.png;compress=true"
    body do
      text "用kamiflex就是這麼簡單",wrap: true
    end
    footer do
      message_button "同意", "不只好用還好潮！真的讚！"
    end
    styles ({ header: {
             backgroundColor: "#ffffff",
             separator: true,
             separatorColor: "#c2c2c2",
           },
             hero: {
             separator: true,
             separatorColor: "#c2c2c2",
           },
             body: {
             backgroundColor: "#ffffff",
             separator: true,
             separatorColor: "#c2c2c2",
           },
             footer: {
             backgroundColor: "#ffffff",
             separator: true,
             separatorColor: "#c2c2c2",
           } })
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
    "header": {
      "type": "box",
      "layout": "vertical",
      "contents": [
        {
          "type": "text",
          "text": "Kamiflex"
        }
      ]
    },
    "hero": {
      "type": "image",
      "url": "https://stickershop.line-scdn.net/stickershop/v1/product/1500785/LINEStorePC/main.png;compress=true"
    },
    "body": {
      "type": "box",
      "layout": "vertical",
      "contents": [
        {
          "type": "text",
          "text": "\b用kamiflex就是這麼簡單",
          "wrap": true
        }
      ]
    },
    "footer": {
      "type": "box",
      "layout": "vertical",
      "contents": [
        {
          "type": "button",
          "action": {
            "type": "message",
            "label": "同意",
            "text": "不只好用還好潮！真的讚！"
          }
        }
      ]
    },
    "styles": {
      "header": {
        "backgroundColor": "#ffffff",
        "separator": true,
        "separatorColor": "#c2c2c2"
      },
      "hero": {
        "separator": true,
        "separatorColor": "#c2c2c2"
      },
      "body": {
        "backgroundColor": "#ffffff",
        "separator": true,
        "separatorColor": "#c2c2c2"
      },
      "footer": {
        "backgroundColor": "#ffffff",
        "separator": true,
        "separatorColor": "#c2c2c2"
      }
    },
    "size": "mega"
  }
}

```