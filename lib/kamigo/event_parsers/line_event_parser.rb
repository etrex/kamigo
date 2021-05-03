module Kamigo
  module EventParsers
    class LineEventParser
      include Kamigo::Clients::LineClient

      def parse_events(request)
        body = request.body.read
        events = client.parse_events_from(body)
        events.map do |event|
          parse(event)
        end
      end

      def parse(event)
        event_hash = JSON.parse(event.to_json, symbolize_names: true)
        payload = event_hash[:src] || event_hash
        line_event = Kamigo::Events::LineEvent.new
        line_event.payload = payload
        line_event.reply_token = event['replyToken']
        line_event.source_type = payload.dig(:source, :type)
        line_event.source_group_id = payload.dig(:source, :groupId) || payload.dig(:source, :roomId) || payload.dig(:source, :userId)
        line_event.source_user_id = payload.dig(:source, :userId) || payload.dig(:source, :groupId) || payload.dig(:source, :roomId)
        line_event.message_type = payload.dig(:message, :type) || payload.dig(:type)
        line_event.message = payload.dig(:message, :text) || payload.dig(:postback, :data) || payload.dig(:message, :address) || line_event.message_type
        line_event.profile = get_profile(line_event)
        line_event
      end

      def get_profile(line_event)
        case line_event.source_type
        when 'group'
          response = client.get_group_member_profile(
            line_event.source_group_id,
            line_event.source_user_id
          )
        when 'room'
          response = client.get_room_member_profile(
            line_event.source_group_id,
            line_event.source_user_id
          )
        else
          response = client.get_profile(line_event.source_user_id)
        end
        JSON.parse(response.body)
      end
    end
  end
end
