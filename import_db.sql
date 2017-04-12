DROP TABLE if EXISTS users;

CREATE  TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255),
  lname VARCHAR(255)
);

DROP TABLE if EXISTS questions;

CREATE  TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255),
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id)
);

DROP TABLE if EXISTS question_follows;

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id)
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

DROP TABLE if EXISTS replies;

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_reply_id INTEGER,
  user_id INTEGER NOT NULL,
  reply TEXT NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id)
  FOREIGN KEY (user_id) REFERENCES users(id)
);

DROP TABLE if EXISTS question_likes;

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id)
  FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Vilya', 'Levitskiy'),
  ('Tony', 'Weng'),
  ('John', 'Smith'),
  ('Adolph', 'Hitler');

INSERT INTO
  questions (title, body, author_id)
VALUES
  ('lunch', 'When does the lunch start?', 1),
  ('location', 'What floor are we on?', 1),
  ('misc', 'Did any one buy my book?', 1),
  ('hitler', 'Who voted for me?', 1);

INSERT INTO
  question_follows (user_id, question_id)
VALUES
  (4, 1),
  (4, 2),
  (4, 3),
  (3, 2);

INSERT INTO
  replies (question_id, parent_reply_id, user_id, reply)
VALUES
  (1, NULL, 2, 'there is no lunch today'),
  (1, 1, 4, 'Lunch is at 12.15'),
  (3, NULL, 1, 'Nope'),
  (3, NULL, 2, 'No way'),
  (3, 4, 4, 'But I did');

INSERT INTO
  question_likes(question_id, user_id)
VALUES
  (2, 1),
  (1, 4),
  (2, 4),
  (3, 4),
  (2, 3),
  (4, 4);
