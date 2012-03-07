require 'test_helper'

class SlidesControllerTest < ActionController::TestCase
  setup do
    @slide = slides(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:slides)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create slide" do
    assert_difference('Slide.count') do
      post :create, slide: @slide.attributes
    end

    assert_redirected_to slide_path(assigns(:slide))
  end

  test "should show slide" do
    get :show, id: @slide
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @slide
    assert_response :success
  end

  test "should update slide" do
    put :update, id: @slide, slide: @slide.attributes
    assert_redirected_to slide_path(assigns(:slide))
  end

  test "should destroy slide" do
    assert_difference('Slide.count', -1) do
      delete :destroy, id: @slide
    end

    assert_redirected_to slides_path
  end
end
