// ------------ Write and expose app ------------ //

var app = angular.module("ShortlyApp", ['ngRoute']);

// --------------- Do some stuff ---------------- //

app.run(function($rootScope, $http, AuthService){
  $rootScope.logOut = AuthService.logout;
});

// ------------- Create App Routes -------------- //

app.config(function($routeProvider, $locationProvider){
  $locationProvider.html5Mode(true);
  $routeProvider
    .when('/', {
      controller: 'LinksController',
      templateUrl: "/templates/home.html"
    })
    .when('/create', {
      controller: 'ShortenController',
      templateUrl: "/templates/create.html"
    })
    .when('/login', {
      controller: 'FrameController',
      templateUrl: "/templates/login.html"
    })
    .otherwise({
      redirectTo: '/'
    });
});

// ---------- Write Controller Logic ------------ //

app.controller('LinksController', function($scope, $http){

  $http({
    method: "GET",
    url: "/links"
  })
  .then(function(obj){
    $scope.links = obj.data;
  })
  .catch(function(err, status){
    $console.log('err', err);
    $scope.links = 'There was an error';
  });
});

app.controller('ShortenController', function($scope, $http){
  $scope.link = {url: null};
  $scope.shortenLink = function(url){
    if (url.$valid){
      $http({
        method: "POST",
        url: "/links",
        data: JSON.stringify($scope.link)
      })
      .then(function(obj){
        console.log(obj);
      })
      .catch(function(obj){
        console.log('err', obj);
      });
    } else {
      $scope.url_error_message = 'Why would you do that? Enter a real URL';
    }
  };
});

app.controller('FrameController', function($scope, UserService, AuthService, $location){

  $scope.user = {
    username: UserService.getUser(),
    password: null
  };
  $scope.logIn = function() {
   AuthService.login($scope.user.username, $scope.user.password)
   .then(function(res){
      if (res.status === 200) {
        UserService.setUser(res.data.auth_code);
        $location.path("/");
      }
    })
    .catch(function(err){
      console.log('err', err);
    });
 };
});

app.service('UserService', function(){
  var currentUser = null;
  this.getUser = function(){
    return currentUser;
  };
  this.setUser = function(u){
    currentUser = u;
  };
});

app.service('AuthService', function($http, $window, $location, UserService){
  this.login = function(username, password) {
    return $http.post('/users/create', JSON.stringify({
      username: username,
      password: password
    }));
  };
  this.logout = function() {
    UserService.setUser(null);
    $location.path('/login');
    // $window.location.href = '/login';
  };
});

app.service('AuthInterceptor', function($location, UserService){
  return {
    'request': function(request) {
      request.token = UserService.getUser();
      return request;
    },
    'responseError': function(rejection) {
      if (rejection.status === 401) {
        $location.path('/login');
      }
      return rejection;
    }
  };
});

app.config(function($httpProvider){
  $httpProvider.interceptors.push('AuthInterceptor');
});