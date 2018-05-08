require('byebug')
require('aws-sdk-s3')
class PostsController < ApplicationController
	before_action :set_course
	before_action :set_course_quiz
	before_action :set_course_quiz_post, only: [:show, :update, :destroy]

	# GET    /courses/:course_id/quizzes/:quiz_id/posts
	def index
		#TODO Test for picture or other form of answer
		json_response(@quiz.posts)
	end

	# GET    /courses/:course_id/quizzes/:quiz_id/posts/:id 
	def show
		#TODO Test for picture or other form of answer
		json_response(@post)
	end

	# POST   /courses/:course_id/quizzes/:quiz_id/posts
	def create
		if @quiz.started
			begin

			post = @quiz.posts.find_by(student_id: @current_user.id) if @quiz
				if post
					#do not use post.update(post_params)
					#we want to overwrite old answers with NULL values 
					#if the type was wrong.
					post.update(:student_id => current_user.id,
									:multiChoice => post_params[:multiChoice],
									:longForm => post_params[:longForm],
									:picture => post_params[:picture],
									:answered => post_params[:answered])
				else
					post = @quiz.posts.create!(:student_id => current_user.id,
									:multiChoice => post_params[:multiChoice],
									:longForm => post_params[:longForm],
									:picture => post_params[:picture],
									:answered => post_params[:answered])
				end
			rescue ActiveRecord::RecordInvalid => e
				throw e
			end
			if post_params[:picture]
					#sw3 connection code
				post_path = "Photos/#{request.fullpath[ 1 .. request.fullpath.length - 1]}/#{post.id}"
				obj = @static_storage_bucket.object(post_path)
					puts post_path
					url = URI.parse(obj.presigned_url(:put))

				json_response(url, :created)
			else
				#return valid post request
				json_response(@post, :created)
			end
				
		else
			json_response(Message.quiz_not_started, 401)
		end
	end

	# PUT    /courses/:course_id/quizzes/:quiz_id/posts/:id
	def update
		@post.update(post_params)
		head :no_content
	end

	# DELETE /courses/:course_id/quizzes/:quiz_id/posts/:id
	def destroy
		@post.destroy
		head :no_content
	end

	private

	def post_params
		params.permit(:answered, :multiChoice, :longForm, :picture)
	end

	def set_course
		@course = Course.find(params[:course_id])
	end

	def set_course_quiz
		@quiz = Quiz.find(params[:quiz_id]) if @course
	end

	def set_course_quiz_post

		@post = @quiz.posts.find(params[:id]) if @quiz
		#@post = @quiz.posts.find_by(student_id: @current_user.id) if @quiz
	end
end
