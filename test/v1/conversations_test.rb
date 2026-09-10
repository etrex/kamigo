require 'minitest/autorun'
require_relative '../../lib/kamigo/identity'
require_relative '../../lib/kamigo/conversations'
require_relative '../../db/migrate/20260909000001_create_kamigo_identity'
require_relative '../../db/migrate/20260909120000_create_kamigo_conversations'
class ConversationsTest < Minitest::Test
  def setup
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Migration.verbose = false
    CreateKamigoIdentity.new.change
    CreateKamigoConversations.new.change
  end
  def test_platform_scope_isolates_rooms_and_membership_is_unique
    person = Kamigo::Identity::Principal.create!
    room = Kamigo::Conversations::Conversation.create!(provider: 'line', scope: 'one', subject: 'group')
    other = Kamigo::Conversations::Conversation.create!(provider: 'line', scope: 'two', subject: 'group')
    member = room.memberships.create!(principal: person)
    assert_empty other.memberships
    assert_equal [person.id], room.memberships.active.pluck(:principal_id)
    assert_raises(ActiveRecord::RecordNotUnique) { room.memberships.create!(principal: person) }
    member.update!(left_at: Time.current)
    assert_empty room.memberships.active
    assert_equal 1, room.memberships.count
  end
  def test_invalid_roles_and_duplicate_rooms_are_rejected
    person = Kamigo::Identity::Principal.create!
    room = Kamigo::Conversations::Conversation.create!(provider: 'telegram', scope: 'bot', subject: '-1')
    assert_raises(ActiveRecord::RecordNotUnique) { Kamigo::Conversations::Conversation.create!(provider: 'telegram', scope: 'bot', subject: '-1') }
    assert_raises(ActiveRecord::RecordInvalid) { room.memberships.create!(principal: person, role: 'superuser') }
    member = room.memberships.create!(principal: person, role: 'admin')
    assert_equal 'admin', member.role
  end
end
