require_relative "../test_case"

class TestUserRole < LinkedData::TestCase

  def teardown
    #roles = LinkedData::Models::Users::Role.where.all
    #roles.each do |role|
    #  role.load
    #  role.delete
    #end
  end

  def test_formats
    teardown

    LinkedData::Models::Users::Role::VALUES.each do |role|
      list = LinkedData::Models::Users::Role.where(role: role)
      assert_equal 1, list.length
      assert_instance_of LinkedData::Models::Users::Role, list[0]
      assert_equal role, list[0].role
    end
  end

  def test_init
     teardown
     assert_equal 0, LinkedData::Models::Users::Role.where.all.length
     LinkedData::Models::Users::Role.init
     assert_equal LinkedData::Models::Users::Role::VALUES.length, LinkedData::Models::Users::Role.where.all.length
  end

end
