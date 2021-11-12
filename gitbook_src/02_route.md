# Route 的使用說明

以下將說明 Kamigo 如何解讀用戶輸入，並且找出對應的 Controller Action。

## 語意理解模型

Kamigo 目前使用了最簡單的解析器去解讀用戶輸入，其格式如下：

```
{{http_method}} {{path}}
{{json}}
```

舉例來說，若用戶輸入如下：

```
GET /todos
```

即視為用戶對 /todos 發出 GET Request。

```
POST /todos
{"todo":{"name":"kamigo"}}
```

即視為用戶對 /todos 發出 POST Reques，並且傳遞一個 json 作為 body。

### 預設值

其中，如果 http_method 是 GET 的話，可省略，path 開頭的 / 也可以省略，所以當用戶的輸入如下：

```
GET /menu
```
或

```
/menu
```

或

```
menu
```

即視為用戶對 /menu 發出 GET Request。

之後 Kamigo 的計畫包含實作支援各大語意理解平台的 Adapter。

## routes

以下示範在 routes.rb 適用於聊天機器人的各種寫法。

#### 可以寫中文

```
get "目錄", to: 'home#menu'
```

如此即可接受用戶輸入「目錄」時，將 Request 轉給 home_controller 的 menu 方法來處理。

#### 可以使用變數

```
get "學 (*keyword) (*message)", to: 'keywords#learn'
```

如此即可接受用戶輸入「學 A B」時，將 Request 轉給 keywords_controller 的 learn 方法來處理，你可以在 controller 當中寫 `params[:keyword]` 取得用戶輸入的 A，寫 `params[:message]` 取得用戶輸入的 B。

#### 最後一個有括號的變數可省略輸入

```
get '(*location)天氣', to: 'weathers#show'
```

如此即可接受用戶輸入「台北天氣」時，將 Request 轉給 weathers_controller 的 show 方法來處理，你可以在 controller 當中寫 `params[:location]` 取得用戶輸入的「台北」。

```
get '(*location)天氣(*other)', to: 'weathers#show'
```

如此即可同時接受用戶輸入「台北天氣」以及「台北天氣如何」。