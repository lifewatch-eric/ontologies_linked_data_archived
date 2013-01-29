require_relative "../test_case"

class TestUserRole < LinkedData::TestCase
  def setup
    @roles = ["ADMIN", "USER"]
  end

  def teardown
    roles = LinkedData::Models::UserRole.all
    roles.each do |role|
      role.load
      role.delete
    end
  end

  def test_formats
    teardown

    @roles.each do |role|
      role = LinkedData::Models::UserRole.new(role: role)
      role.save
    end

    @roles.each do |role|
      list = LinkedData::Models::UserRole.where(role: role)
      assert_equal 1, list.length
      assert_instance_of LinkedData::Models::UserRole, list[0]
      list[0].load
      assert_equal role, list[0].role
    end
  end

  def test_init
     teardown
     assert_equal 0, LinkedData::Models::UserRole.all.length
     LinkedData::Models::UserRole.init @roles
     assert_equal 2, LinkedData::Models::UserRole.all.length
  end

end
