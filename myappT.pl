#!/usr/bin/env perl

use v5.16;
use utf8;

use Mojolicious::Lite;

use DBI;

my $DBH = DBI->connect(
    'dbi:mysql:Book',
    'root',
    '*Hay990729', #password(mysql)
    {
        RaiseError        => 1,
        AutoCommit        => 1,
        mysql_enable_utf8 => 1,
    },
);

helper db_select => sub {
    my ( $self, $input_id ) = @_;

    my $sth = $DBH->prepare(qq{ SELECT * FROM MEMO WHERE id=$input_id});
    $sth->execute();

    my %articles;
    my ( $db_id, $name, $title, $content, $date ) = $sth->fetchrow_array;
    my ($wdate) = split / /, $date;

    $articles{$db_id} = {
        name    => $name,
        title   => $title,
        content => $content,
        wdate   => $wdate,
    };

    return \%articles;
};

get '/' => sub {
    my $self = shift;

    $self->redirect_to( $self->url_for('/login') );
};

get '/list' => sub {
    my $self = shift;

    my $sth = $DBH->prepare(qq{ SELECT id, name, title, content, wdate FROM MEMO });
    $sth->execute();

    my %articles;
    while ( my @row = $sth->fetchrow_array ) {
        my ( $id, $name, $title, $content, $date ) = @row;
        my ($wdate) = split / /, $date;

        $articles{$id} = {
            name    => $name,
            title   => $title,
            content => $content,
            wdate   => $wdate,
        };
    }

    $self->stash( articles => \%articles );
};

###################추가#################
get '/createID' => sub { #페이지를 열기
  my $self = shift;

  $self->render('createID');
};

post '/createID' => sub { #디비로 저장하는 POST
    my $self = shift;
 
    my $userid   = $self->param('userid');
    my $passwd   = $self->param('passwd');
 
    my $sth = $DBH->prepare(qq{
        INSERT INTO `USER` (`userid`,`passwd`) VALUES (?,?)
    });
    $sth->execute($userid, $passwd);
    #$self->redirect_to( $self->url_for('/login') ); #조건에 따라 경로가 달라져야함 추후 수정
};

get '/login' => sub {
  my $self = shift;

  $self->render('login');
};
################추가#################

get '/write' => sub {
  my $self = shift;
 
  $self->render('write');
};

post '/write' => sub {
    my $self = shift;

    my $name    = $self->param('name');
    my $title   = $self->param('title');
    my $content = $self->param('content');

    my $sth = $DBH->prepare(qq{
        INSERT INTO `memo` (`name`,`title`,`content`) VALUES (?,?,?)
    });
    $sth->execute( $name, $title, $content );

    $self->redirect_to( $self->url_for('/list') );
};

get '/read/:id' => sub {
    my $self = shift;

    my $input_id = $self->param('id');

    my $articles = $self->db_select ( $input_id );
    my ($id)     = keys %$articles;

    $self->stash(
        articles => $articles,
        id       => $id,
    );
    $self->render('read');
};

get '/edit/:id' => sub {
    my $self = shift;

    my $input_id = $self->param('id');

    my $articles = $self->db_select ( $input_id );
    my ($id)     = keys %$articles;

    $self->stash(
        articles => $articles,
        id       => $id,
    );
    $self->render('edit');
};

post '/edit' => sub {
    my $self = shift;

    my $id      = $self->param('id');
    warn $id;
    my $name    = $self->param('name');
    my $title   = $self->param('title');
    my $content = $self->param('content');

    my $sth = $DBH->prepare(qq{
        UPDATE `memo` SET `name`=?,`title`=?,`content`=? WHERE `id`=$id
    });
    $sth->execute( $name, $title, $content );

    $self->redirect_to( $self->url_for('/list') );
};

get '/delete/:id' => sub {
    my $self = shift;

    my $id = $self->param('id');

    my $sth = $DBH->prepare(qq{ DELETE FROM `memo` WHERE `id`=$id });
    $sth->execute();

    $self->redirect_to( $self->url_for('/list') );
};

app->start;
__DATA__
@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
  </head>
  <body>
    <%= content %>
  </body>
</html>


#######로그인 HTML###############
@@ login.html.ep
% layout 'default';
% title 'SIGN IN';
<style>
a {
    color: #333;
    text-decoration: none;
    float: right;
}
input {
    -webkit-writing-mode: horizontal-tb !important;
    text-rendering: auto;
    color: initial;
    letter-spacing: normal;
    word-spacing: normal;
    text-transform: none;
    text-indent: 0px;
    text-shadow: none;
    display: inline-block;
    text-align: start;
    -webkit-appearance: textfield;
    background-color: white;
    -webkit-rtl-ordering: logical;
    cursor: text;
    margin: 0em;
    font: 400 13.3333px Arial;
    padding: 1px 0px;
    border-width: 2px;
    border-style: inset;
    border-color: initial;
    border-image: initial;
}
.inner_login {
    position: absolute;
    left: 50%;
    top: 50%;
    margin: -145px 0 0 -160px;
}
.login_pananyang{
        position: relative;
        width: 320px;
        margin: 0 auto;
    }
.screen_out {
    position: absolute;
    width: 0;
    height: 0;
    overflow: hidden;
    line-height: 0;
    text-indent: -9999px;    
}
body, button, input, select, td, textarea, th {
    font-size: 13px;
    line-height: 1.5;
    -webkit-font-smoothing: antialiased;
}    
fieldset, img {
    border: 0;
}
.login_pananyang .box_login {
    margin: 35px 0 0;
    border: 1px solid #ddd;
    border-radius: 3px;
    background-color: #fff;
    box-sizing: border-box;
}
.login_pananyang .inp_text {
    position: relative;
    width: 100%;
    margin: 0;
    padding: 18px 19px 19px;
    box-sizing: border-box;
}
.login_pananyang .inp_text+.inp_text {
    border-top: 1px solid #ddd;
}
.inp_text input {
    display: block;
    width: 100%;
    height: 100%;
    font-size: 13px;
    color: #000;
    border: none;
    outline: 0;
    -webkit-appearance: none;
    background-color: transparent;
}
.btn_login {
    margin: 20px 0 0;
    width: 100%;
    height: 48px;
    border-radius: 3px;
    border-color: #777;
    font-size: 16px;
    color: #fff;
    background-color: #777;
}
</style>

<div class="inner_login">
    <div class="login_pananyang">

        <form action="/login" method="post">
            <fieldset>
            <legend class="screen_out">로그인 정보 입력폼</legend>
            <div class="box_login">
                <div class="inp_text">
                <label for="loginId" class="screen_out">아이디</label>
                <input type="text" id="loginId" name="loginId" placeholder="ID" >
                </div>
                <div class="inp_text">
                <label for="loginPw" class="screen_out">비밀번호</label>
                <input type="password" id="loginPw" name="password" placeholder="Password" >
                </div>
            </div>
            <button type="submit" class="btn_login"  anabled>로그인</button> 
                <span class="txt_find">
                <a href="http://127.0.0.1:3000/createID" class="link_find">아직 회원이 아니시라면 / 회원가입 </a>
                </span>
            </div>
            </fieldset>
        </form>
        
    </div>
</div>

############로그인 HTML################
###########회원가입 HTML###############
@@ createID.html.ep
% layout 'default';
% title 'SIGN UP';
<style>
a {
    color: #333;
    text-decoration: none;
    float: right;
}
input {
    -webkit-writing-mode: horizontal-tb !important;
    text-rendering: auto;
    color: initial;
    letter-spacing: normal;
    word-spacing: normal;
    text-transform: none;
    text-indent: 0px;
    text-shadow: none;
    display: inline-block;
    text-align: start;
    -webkit-appearance: textfield;
    background-color: white;
    -webkit-rtl-ordering: logical;
    cursor: text;
    margin: 0em;
    font: 400 13.3333px Arial;
    padding: 1px 0px;
    border-width: 2px;
    border-style: inset;
    border-color: initial;
    border-image: initial;
}
.inner_createID {
    position: absolute;
    left: 50%;
    top: 50%;
    margin: -145px 0 0 -160px;
}
.createID_pananyang{
        position: relative;
        width: 320px;
        margin: 0 auto;
    }
.screen_out {
    position: absolute;
    width: 0;
    height: 0;
    overflow: hidden;
    line-height: 0;
    text-indent: -9999px;    
}
body, button, input, select, td, textarea, th {
    font-size: 13px;
    line-height: 1.5;
    -webkit-font-smoothing: antialiased;
}    
fieldset, img {
    border: 0;
}
.createID_pananyang .box_createID {
    margin: 35px 0 0;
    border: 1px solid #ddd;
    border-radius: 3px;
    background-color: #fff;
    box-sizing: border-box;
}
.createID_pananyang .inp_text {
    position: relative;
    width: 100%;
    margin: 0;
    padding: 18px 19px 19px;
    box-sizing: border-box;
}
.createID_pananyang .inp_text+.inp_text {
    border-top: 1px solid #ddd;
}
.inp_text input {
    display: block;
    width: 100%;
    height: 100%;
    font-size: 13px;
    color: #000;
    border: none;
    outline: 0;
    -webkit-appearance: none;
    background-color: transparent;
}
.btn_createID {
    margin: 20px 0 0;
    width: 100%;
    height: 48px;
    border-radius: 3px;
    border-color: #777;
    font-size: 16px;
    color: #fff;
    background-color: #777;
}
</style>

<div class="inner_createID">
    <div class="createID_pananyang">

        <form action="/createID" method="post">
            <fieldset>
            <legend class="screen_out">회원가입 정보 입력폼</legend>
            <div class="box_createID">
                <div class="inp_text">
                <label for="loginId" class="screen_out">아이디</label>
                <input type="text" id="userid" name="userid" placeholder="20자 이내의 문자열을 입력하세요" >
                </div>
                <div class="inp_text">
                <label for="loginPw" class="screen_out">비밀번호</label>
                <input type="password" id="passwd" name="passwd" placeholder="10자 이내의 숫자를 입력하세요" >
                </div>
            </div>
            <button type="submit" class="btn_createID"  anabled>가입하기</button> 
            </fieldset>
        </form>
    </div>
</div>

###########회원가입 HTML###############



@@ write.html.ep
% layout 'default';
% title 'WRITE';
      <form action="/write" method="post">
        <table width=580 border=0 cellpadding=2 cellspacing=1 bgcolor=#777777>
          <tr>
            <td height=20 colspan=4 align=center bgcolor=#999999>
              <font color=white><b>글쓰기</b></font>
            </td>
          </tr>
          <tr>
            <td bgcolor=white>
              <table bgcolor=white>
                <tr>
                  <td>이름</td>
                  <td><input type="text" name="name"></td>
                </tr>
                <tr>
                  <td>제목</td>
                  <td><input type="text" name="title"></td>
                </tr>
                <tr>
                  <td>내용</td>
                  <td colspan=4>
                    <textarea name="content" cols=80 rows=5></textarea>
                  </td>
                </tr>
                <tr>
                  <td colspan=10 align=center>
                    <input type="submit" value="저장">
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        <tr>
          <td bgcolor=#999999>
            <table width=100%>
              <tr>
                <td>
                  <a href='/list' style="text-decoration:none;"><font color=white>[목록보기]</font></a>
                </td>
              </tr>
            </table>
          </td>
        </tr>
        </table>
      </form>
@@ list.html.ep
% layout 'default';
% title 'LIST';
        <table width=580 border=0 cellpadding=2 cellspacing=1 bgcolor=#999999>
        <tr height=20 colspan=4 align=center bgcolor=#CCCCCC >
          <td color=white>No. </td>
          <td>제목</td>
          <td>글쓴이</td>
          <td>date</td>
        </tr>
        % for my $id ( reverse sort { $a <=> $b } keys %$articles ) {
        <tr bgcolor="white">
          <td><%= $id %></td>
          <td><a href="/read/<%= $id %>"><%= $articles->{$id}{title} %></a></td>
          <td><%= $articles->{$id}{name} %></td>
          <td><%= $articles->{$id}{wdate} %></td>
        </tr>
        % }
        <tr>
          <td colspan=4 bgcolor=#999999>
            <table width=100%>
              <tr>
                <td width=2000 align=center height=20>
                  <a href='/write' style="text-decoration:none;"><font color=white>[글쓰기]</font></a>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
@@ read.html.ep
% layout 'default';
% title 'READ';
      <table width=580 border=0 cellpadding=2 cellspacing=1 bgcolor=#777777>
        <tr>
          <td height=20 colspan=4 align=center bgcolor=#999999>
            <font color=white><b><%= $articles->{$id}{title} %></b></font>
          </td>
        </tr>
        <tr>
          <td width=50 height=20 align=center bgcolor=#EEEEEE> 글쓴이 </td>
          <td width=240 bgcolor=white> <%= $articles->{$id}{name} %> </td>
          <td width=50 height=20 align=center bgcolor=#EEEEEE> 날짜 </td>
          <td width=240 bgcolor=white> <%= $articles->{$id}{wdate} %> </td>
        </tr>
        <tr>
          <td bgcolor=white colspan=4>
            <font color=black>
              <pre><%= $articles->{$id}{content} %></pre>
            </font>
          </td>
        </tr>
        <tr>
          <td colspan=4 bgcolor=#999999>
            <table width=100%>
              <tr>
                <td width=2000 align=left height=20>
                  <a href='/list' style="text-decoration:none;"><font color=white>[목록보기]</font></a>
                  <a href='/write' style="text-decoration:none;"><font color=white>[글쓰기]</font></a>
                  <a href='/edit/<%= $id %>' style="text-decoration:none;"><font color=white>[수정]</font></a>
                  <a href='/delete/<%= $id %>' style="text-decoration:none;"><font color=white>[삭제]</font></a>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
@@ edit.html.ep
% layout 'default';
% title 'EDIT';
      <form action="/edit" method="post">
        <input type="hidden" name="id" value="<%= $id %>">
        <table width=580 border=0 cellpadding=2 cellspacing=1 bgcolor=#777777>
          <tr>
            <td height=20 colspan=4 align=center bgcolor=#999999>
              <font color=white><b>수정</b></font>
            </td>
          </tr>
          <tr>
            <td bgcolor=white>
              <table bgcolor=white>
                <tr>
                  <td>이름</td>
                  <td><input type="text" name="name" value="<%= $articles->{$id}{name} %>"></td>
                </tr>
                <tr>
                  <td>제목</td>
                  <td><input type="text" name="title" value="<%= $articles->{$id}{title} %>"></td>
                </tr>
                <tr>
                  <td>내용</td>
                  <td colspan=4>
                    <textarea name="content" cols=80 rows=5><%= $articles->{$id}{content} %></textarea>
                  </td>
                </tr>
                <tr>
                  <td colspan=10 align=center>
                    <input type="submit" value="수정확인">
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        <tr>
          <td bgcolor=#999999>
            <table width=100%>
              <tr>
                <td>
                  <a href='/list' style="text-decoration:none;"><font color=white>[목록보기]</font></a>
                  <a href='/write' style="text-decoration:none;"><font color=white>[글쓰기]</font></a>
                  <a href='/read/<%= $id %>' style="text-decoration:none;"><font color=white>[취소]</font></a>
                  <a href='/delete/<%= $id %>' style="text-decoration:none;"><font color=white>[삭제]</font></a>
                </td>
              </tr>
            </table>
          </td>
        </tr>
        </table>
      </form>
