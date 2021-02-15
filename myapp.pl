
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

    my $sth = $DBH->prepare(qq{ SELECT * FROM memo WHERE id=$input_id});
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

    $self->redirect_to( $self->url_for('/list') );
};

get '/list' => sub {
    my $self = shift;

    my $sth = $DBH->prepare(qq{ SELECT id, name, title, content, wdate FROM memo });
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
