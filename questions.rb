require 'sqlite3'
require 'singleton'
require 'byebug'
class QuestionsDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  attr_accessor :fname, :lname
  attr_reader :id
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def average_karma
    avg = QuestionsDBConnection.instance.execute(<<-SQL, @id)
    SELECT
       COUNT(ql) / CAST (COUNT(DISTINCT q) AS FLOAT)  
    FROM
      (SELECT
        questions.title AS q, question_likes.id AS ql
      FROM
        questions
        LEFT OUTER JOIN
          question_likes
          ON
            questions.id = question_likes.question_id
      WHERE questions.author_id = ?) AS l
    SQL
    avg.first.values[0]
  end

  def self.find_by_id(id)
    user = QuestionsDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    return nil unless user.length > 0

    User.new(user.first)
  end

  def self.find_by_name(fname, lname)
    user = QuestionsDBConnection.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ?
        lname = ?
    SQL
    return nil unless user.length > 0

    User.new(user.first)
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollows.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

end

class Question
  attr_accessor :title, :body, :author_id

    def initialize(options)
      @id = options['id']
      @title = options['title']
      @body = options['body']
      @author_id = options['author_id']
    end

    def self.find_by_id(id)
      question = QuestionsDBConnection.instance.execute(<<-SQL, id)
          SELECT
            *
          FROM
            questions
          WHERE
            id = ?
      SQL
      return nil unless question.length > 0

      Question.new(question.first)
    end

    def self.find_by_title(title)
      question = QuestionsDBConnection.instance.execute(<<-SQL, title)
        SELECT
          *
        FROM
          questions
        WHERE
          title = ?
      SQL
      return nil unless question.length > 0

      Question.new(question.first)
    end

    def self.find_by_author_id(author_id)
      question = QuestionsDBConnection.instance.execute(<<-SQL, author_id)
          SELECT
            *
          FROM
            questions
          WHERE
            author_id = ?
      SQL
      return nil unless question.length > 0

      question.map { |quest| Question.new(quest) }
    end

    def author
      User.find_by_id(@author_id)
    end

    def replies
      Reply.find_by_question_id(@id)
    end

    def followers
      QuestionFollows.followers_for_question_id(@id)
    end

    def likers
      QuestionLike.likers_for_question_id(@id)
    end

    def num_likes
      QuestionLike.num_likes_for_question_id(@id)
    end

    def self.most_liked(n)
      questions = QuestionsDBConnection.instance.execute(<<-SQL, n)
        SELECT
          questions.title
        FROM
          questions
          JOIN question_likes
            ON question_likes.question_id = questions.id
        GROUP BY questions.title
        ORDER BY COUNT(question_id) DESC
        LIMIT ?
      SQL
      return nil unless questions.length > 0
      questions.map {|q| Question.new(q)}
    end

end

class QuestionFollows
  attr_accessor :user_id, :question_id
  attr_reader :id

  def initialize(options)
    @id = id
    @user_id = user_id
    @question_id = question_id
  end

  def self.find_by_id(id)
    follows = QuestionsDBConnection.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      question_follows
    WHERE
      id = ?

  SQL
    return nil unless follows.length > 0

    QuestionFollows.new(follows.first)
  end

  def self.followers_for_question_id(question_id)
    followers = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        users
        JOIN question_follows
          ON user_id = users.id
      WHERE
        question_id = ?
    SQL
    return nil unless followers.length > 0
    followers.map { |follower| User.new(follower) }
  end

  def self.followed_questions_for_user_id(user_id)
    following = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        questions
        JOIN question_follows
        ON  question_id = questions.id
      WHERE
        user_id = ?
    SQL
    return nil unless following.length > 0
    following.map { |follow| User.new(follow)}
  end

  def self.most_followed_questions(n)
    questions = QuestionsDBConnection.instance.execute(<<-SQL, n)
      SELECT
        questions.title
      FROM
        questions
        JOIN question_follows
        ON  question_id = questions.id
      GROUP BY questions.title
      ORDER BY COUNT(question_id) DESC
      LIMIT ?
    SQL
    return nil unless questions.length > 0
    questions.map { |question| Question.new(question)}
  end

end

class Reply
  attr_accessor :question_title, :parent_reply_id, :user_id, :reply
  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent_reply_id = options['parent_reply_id']
    @user_id = options['user_id']
    @reply = options['reply']
  end

  def self.find_by_user_id(user_id)
    reply = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
    SQL
    return nil unless reply.length > 0

    reply.map { |rep| Reply.new(rep) }
  end

  def self.find_by_question_id(question_id)
    debugger
    reply = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL
    return nil unless reply.length > 0
    reply.map {|rep| Reply.new(rep)}
  end

  def author
    User.find_by_id(@user_id)
  end

  def question
    Question.find_by_id(@question_id)
  end

  def parent_reply
    Reply.find_by_id(@parent_reply_id)
  end

  def self.find_by_id(id)
    reply = QuestionsDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    return nil unless reply.length > 0

    Reply.new(reply.first)
  end

  def child_replies
    children = QuestionsDBConnection.instance.execute(<<-SQL, @id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_reply_id = ?
    SQL
    return nil unless children.length > 0

    children.map { |child| Reply.new(child) }
  end

end

class QuestionLike

  attr_accessor :id, :question_id, :user_id

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end

  def self.likers_for_question_id(question_id)
    likers = QuestionsDBConnection.instance.execute(<<-SQL, question_id)

      SELECT
        *
      FROM
        users
      JOIN
        question_likes
      ON
        question_likes.user_id = users.id
      WHERE
        question_likes.question_id = ?
    SQL
    return nil unless likers.length > 0
    likers.map { |liker| User.new(liker)}
  end

  def self.num_likes_for_question_id(question_id)
    num = QuestionsDBConnection.instance.execute(<<-SQL, question_id)

      SELECT
        COUNT(users.id)
      FROM
        users
      JOIN
        question_likes
      ON
        question_likes.user_id = users.id
      WHERE
        question_likes.question_id = ?
    SQL
    return nil unless num.length > 0
    num.first.values[0]
  end

  def self.liked_questions_for_user_id(user_id)
    liked_questions = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
      SELECT
        questions.title
      FROM
        questions
        JOIN question_likes
          ON questions.id = question_likes.question_id
        WHERE
          question_likes.user_id = ?
      SQL
      return nil unless liked_questions.length > 0
      liked_questions.map { |lq| Question.new(lq) }
  end

  def self.most_liked_questions(n)
    questions = QuestionsDBConnection.instance.execute(<<-SQL, n)
      SELECT
        questions.title
      FROM
        questions
      JOIN
        question_likes
        ON
        question_likes.question_id = questions.id
      GROUP BY questions.title
      ORDER BY COUNT(questions.id) DESC
      LIMIT ?
    SQL
    return nil unless questions.length > 0
    questions.map {|q| Question.new(q)}
  end
end
