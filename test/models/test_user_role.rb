require_relative "../test_case"

class TestUserRole < LinkedData::TestCase

  def after_suites
    puts "Deleting user roles"
    roles = LinkedData::Models::Users::Role.where.all
    roles.each do |role|
      role.delete(force = true)
    end
  end

  def test_formats
    teardown
    LinkedData::Models::Users::Role.init

    LinkedData::Models::Users::Role::VALUES.each do |role|
      list = LinkedData::Models::Users::Role.where(role: role).include(:role)
      assert_equal 1, list.length
      assert_instance_of LinkedData::Models::Users::Role, list.first
      assert_equal role, list.first.role
    end
  end

  def test_init
     teardown
     assert_equal 0, LinkedData::Models::Users::Role.where.all.length
     LinkedData::Models::Users::Role.init
     assert_equal LinkedData::Models::Users::Role::VALUES.length, LinkedData::Models::Users::Role.where.all.length
  end

end
