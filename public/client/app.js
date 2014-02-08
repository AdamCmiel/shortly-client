// ------------ Write and expose app ------------ //

var app = angular.module("ShortlyApp", ['ngRoute']);

// --------------- Do some stuff ---------------- //

app.run(function($rootScope, $http){
  $rootScope.logOut = function() {
    $http({
      method: "GET",
      url: "/logout"
    });
  };
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
      controller: 'LoginController',
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
  $scope.shortenLink = function(){
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
  };
});

app.controller('LoginController', function($scope, $http, $location){
  $scope.user = {
    username: null,
    password: null
  };

  $scope.logIn = function() {
    $http({
      method: "POST",
      url: "/users/create",
      data: JSON.stringify($scope.user)
    })
    .then(function(obj) {
      $location.path("/");
    })
    .catch(function(obj) {
      console.log(obj);
    });
  };
});
