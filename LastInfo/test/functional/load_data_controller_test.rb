require 'test_helper'

class LoadDataControllerTest < ActionController::TestCase
  setup do
    @load_datum = load_data(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:load_data)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create load_datum" do
    assert_difference('LoadDatum.count') do
      post :create, :load_datum => @load_datum.attributes
    end

    assert_redirected_to load_datum_path(assigns(:load_datum))
  end

  test "should show load_datum" do
    get :show, :id => @load_datum
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @load_datum
    assert_response :success
  end

  test "should update load_datum" do
    put :update, :id => @load_datum, :load_datum => @load_datum.attributes
    assert_redirected_to load_datum_path(assigns(:load_datum))
  end

  test "should destroy load_datum" do
    assert_difference('LoadDatum.count', -1) do
      delete :destroy, :id => @load_datum
    end

    assert_redirected_to load_data_path
  end
end
