# 核心元件
核心元件需被寫在Flex Message Meta的block之中。
## bubble
#### 說明
此元件為Flex Message最基礎之核心元件。
![](https://developers.line.biz/assets/img/overviewSample.772a618f.png) <br/>
詳細說明請參考以下連結：<br/>
[LINE Flex Message 關於 Bubble 的說明文件](https://developers.line.biz/en/docs/messaging-api/flex-message-elements/#bubble) <br/>
[LINE Flex Message 關於 Bubble 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#bubble)
#### 相關參數
請參考官方文件中的[bubble](https://developers.line.biz/en/reference/messaging-api/#bubble)

#### 使用範例
Ruby寫法：
```ruby
Kamiflex.build(self) do
  bubble size: "nano",direction: "ltr" do
    body do
      text "Hello, World!"
    end
  end
end
```
對應的Json：
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
此元件需使用在`carousel`之中，達成橫向多筆Flex Message，若不使用此核心元件，亦可使用Ruby原生的`#each`搭配`bubble`達到相同功能。
#### 相關參數
與`bubble`相同，請參考官方文件中的[bubble](https://developers.line.biz/en/reference/messaging-api/#bubble)
#### 使用範例
使用`bubbles`的Ruby寫法：
```ruby
@strings = ["string1", "string2", "string3"]
Kamiflex.build(self) do
  carousel do
    bubbles @strings, size: "nano", direction: "ltr" do |string|
      body do
        text string
      end
    end
  end
end
```
不使用`bubbles`的Ruby寫法：
```ruby
Kamiflex.build(self) do
  carousel do
    @strings.each do |string|
      bubble size: "nano", direction: "ltr" do
        body do
          text string
        end
      end
    end
  end
end
```
對應的Json：
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
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": "string1"
            }
          ]
        },
        "size": "nano",
        "direction": "ltr"
      },
      {
        "type": "bubble",
        "body": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": "string2"
            }
          ]
        },
        "size": "nano",
        "direction": "ltr"
      },
      {
        "type": "bubble",
        "body": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": "string3"
            }
          ]
        },
        "size": "nano",
        "direction": "ltr"
      }
    ]
  }
}

```

## carousel
#### 說明
此元件可以達成橫向多筆的Flex Message，但在其之中還需要加上bubble元件。
![](https://developers.line.biz/assets/img/carouselSample.b7d44737.png)<br>
[LINE Flex Message 關於 Carousel 的說明文件](https://developers.line.biz/en/docs/messaging-api/flex-message-elements/#carousel) <br/>
[LINE Flex Message 關於 Carousel 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#f-carousel)
#### 相關參數
最多僅能12個`bubble`
#### 使用範例
使用`bubbles`的Ruby寫法：
```ruby
@strings = ["string1", "string2", "string3"]
Kamiflex.build(self) do
  carousel do
    bubbles @strings, size: "nano", direction: "ltr" do |string|
      body do
        text string
      end
    end
  end
end
```
不使用`bubbles`的Ruby寫法：
```ruby
Kamiflex.build(self) do
  carousel do
    @strings.each do |string|
      bubble size: "nano", direction: "ltr" do
        body do
          text string
        end
      end
    end
  end
end
```
對應的Json：
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
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": "string1"
            }
          ]
        },
        "size": "nano",
        "direction": "ltr"
      },
      {
        "type": "bubble",
        "body": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": "string2"
            }
          ]
        },
        "size": "nano",
        "direction": "ltr"
      },
      {
        "type": "bubble",
        "body": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": "string3"
            }
          ]
        },
        "size": "nano",
        "direction": "ltr"
      }
    ]
  }
}

```

# 屬性
核心元件屬性需放置在bubble或是bubbles的block之中，並且各個屬性應確保其Json同層而不存在上下層關聯。
## header
#### 說明
呈現在Flex Message最頂部，一般用來放置標題使用
#### 相關參數
Kamflex會為`header`自動創立一個容器元件`box`，關於容器元件`box`參數請參考官方文件中的[box](https://developers.line.biz/en/reference/messaging-api/#box)
> 此處無法直接使用`header`參數，若想使用`header`參數請搭配[styles](#styles)

#### 使用範例
Ruby的寫法：
```ruby
Kamiflex.build(self) do
  bubble do
    header layout: "vertical", borderWidth: "light", backgroundColor: "#c3c3c3" do
      text "hello, wrold!"
    end
  end
end
```
對應的json：
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
呈現在Flex Message `header`之下，`body`之上，一般用來放置圖片，**由於不需要搭配block。後方不需再加入`{...}`或是`do...end`**。
#### 相關參數
kamiflex預設`hero`的`type`為`image`元件，因此需搭配[image元件參數](https://developers.line.biz/en/reference/messaging-api/#f-image)使用
> 此處無法直接使用`hero`參數，若想使用`hero`參數請搭配[styles](#styles)

> `hero`的`type`除了`image`元件外，也可以選擇為`box`元件

#### 使用範例
Ruby的寫法：
```ruby
Kamiflex.build(self) do
    bubble do
        hero "https://scdn.line-apps.com/n/channel_devcenter/img/fx/01_1_cafe.png",
size: :full, aspectRatio: "20:13"
    end
end
```
對應的json:
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
呈現在Flex Message中間的位置，一般用於表達內文。
#### 參數
Kamflex會為`body`自動創立一個容器元件`box`，關於容器元件`box`參數請參考官方文件中的[box](https://developers.line.biz/en/reference/messaging-api/#box)
> 此處無法直接使用`body`參數，若想使用`body`參數請搭配[styles](#styles)

#### 使用範例
Ruby寫法：
```ruby
Kamiflex.build(self) do
  bubble do
    body layout: "vertical", borderWidth: "light", backgroundColor: "#c3c3c3" do
      text "hello, wrold!"
    end
  end
end
```
對應的json：
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
呈現在Flex Message最底部的位置，一般用於放置按鈕。
#### 參數
Kamflex會為`footer`自動創立一個容器元件`box`，關於容器元件`box`參數請參考官方文件中的[box](https://developers.line.biz/en/reference/messaging-api/#box)
> 此處無法直接使用`footer`參數，若想使用`body`參數請搭配[styles](#styles)

#### 使用範例
Ruby寫法：
```ruby
Kamiflex.build(self) do
  bubble do
    footer layout: "vertical", borderWidth: "light", backgroundColor: "#c3c3c3" do
      text "hello, wrold!"
    end
  end
end
```
對應的json：
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
主要功能為更改核心元件屬性的style。
#### 相關參數
請參考官方文件中的[block style](https://developers.line.biz/en/reference/messaging-api/#block-style)
#### 使用範例
Ruby寫法：
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
             "backgroundColor": "#ffffff",
             "separator": true,
             "separatorColor": "#c2c2c2",
           },
             hero: {
             "separator": true,
             "separatorColor": "#c2c2c2",
           },
             body: {
             "backgroundColor": "#ffffff",
             "separator": true,
             "separatorColor": "#c2c2c2",
           },
             footer: {
             "backgroundColor": "#ffffff",
             "separator": true,
             "separatorColor": "#c2c2c2",
           } })
  end
end
```
對應的json：
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