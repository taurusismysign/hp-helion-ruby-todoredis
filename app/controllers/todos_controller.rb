require 'redis'

class TodosController < ApplicationController
  before_action :set_todo, only: [:show, :edit, :update, :destroy]
  after_action :delete_indexed_values, only: [:create, :edit, :update, :destroy]
  after_action :dev_mode
  before_action :cleanup_mode

  # GET /todos
  # GET /todos.json
  def index
    @title = ENV['TITLE'] || "TODO Application (Dev)"

    redis = get_redis_connection

    todojson = redis.get "index"

    if todojson.blank?
      todoactiverecord = Todo.all
      #save in REDIS
      todojson = todoactiverecord.to_json
      redis.set "index",todojson
    end

    @todos = ActiveSupport::JSON.decode todojson


  end

  # GET /todos/1
  # GET /todos/1.json
  def show
  end

  # GET /todos/new
  def new
    @todo = Todo.new
  end

  # GET /todos/1/edit
  def edit
  end

  # POST /todos
  # POST /todos.json
  def create
    @todo = Todo.new(todo_params)

    respond_to do |format|
      if @todo.save
        format.html { redirect_to @todo, notice: 'Todo was successfully created.' }
        format.json { render :show, status: :created, location: @todo }
      else
        format.html { render :new }
        format.json { render json: @todo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /todos/1
  # PATCH/PUT /todos/1.json
  def update
    respond_to do |format|
      if @todo.update(todo_params)
        format.html { redirect_to @todo, notice: 'Todo was successfully updated.' }
        format.json { render :show, status: :ok, location: @todo }
      else
        format.html { render :edit }
        format.json { render json: @todo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /todos/1
  # DELETE /todos/1.json
  def destroy
    @todo.destroy
    respond_to do |format|
      format.html { redirect_to todos_url, notice: 'Todo was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    def delete_indexed_values
      redis = get_redis_connection
      redis.del("index")
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_todo
      @todo = Todo.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def todo_params
      params.require(:todo).permit(:description, :is_completed, :target_date)
    end

    def get_redis_connection

      u = ENV['REDIS_URL']

      if ENV['VCAP_SERVICES'].present?
        vcap = JSON.parse(ENV['VCAP_SERVICES'])["redis"]
        credentials = vcap.first["credentials"]
        u = credentials["uri"]
      end

      Redis.new(:url => u)

    end


  def cleanup_mode
    #also, delete the redis (flushall). We are doing this, just so
    #that there is a way to clear redis
    if params[:flushredis]
      redis = get_redis_connection
      redis.flushall
    end
  end

  def dev_mode

    #if in the query string you pass debug=true (or any value for debug, it will print the VCAP_APPLICATION)
    #mainly used to see multiple instance working and which particular instance the page got served.
    if params[:debug]
      @vcap_details = "VCAP details not available"
      @vcap_details = JSON.parse(ENV['VCAP_SERVICES']) if ENV['VCAP_SERVICES'].present?
    end

  end

end
