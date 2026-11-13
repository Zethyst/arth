// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contracts.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DictionaryEntry {

 String get word; String get ipa; String get hindiPronunciation; List<Sense> get senses; List<BilingualPair> get synonyms; List<BilingualPair> get antonyms; List<WordForm> get forms; bool get isPhrase;
/// Create a copy of DictionaryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DictionaryEntryCopyWith<DictionaryEntry> get copyWith => _$DictionaryEntryCopyWithImpl<DictionaryEntry>(this as DictionaryEntry, _$identity);

  /// Serializes this DictionaryEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DictionaryEntry&&(identical(other.word, word) || other.word == word)&&(identical(other.ipa, ipa) || other.ipa == ipa)&&(identical(other.hindiPronunciation, hindiPronunciation) || other.hindiPronunciation == hindiPronunciation)&&const DeepCollectionEquality().equals(other.senses, senses)&&const DeepCollectionEquality().equals(other.synonyms, synonyms)&&const DeepCollectionEquality().equals(other.antonyms, antonyms)&&const DeepCollectionEquality().equals(other.forms, forms)&&(identical(other.isPhrase, isPhrase) || other.isPhrase == isPhrase));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,word,ipa,hindiPronunciation,const DeepCollectionEquality().hash(senses),const DeepCollectionEquality().hash(synonyms),const DeepCollectionEquality().hash(antonyms),const DeepCollectionEquality().hash(forms),isPhrase);

@override
String toString() {
  return 'DictionaryEntry(word: $word, ipa: $ipa, hindiPronunciation: $hindiPronunciation, senses: $senses, synonyms: $synonyms, antonyms: $antonyms, forms: $forms, isPhrase: $isPhrase)';
}


}

/// @nodoc
abstract mixin class $DictionaryEntryCopyWith<$Res>  {
  factory $DictionaryEntryCopyWith(DictionaryEntry value, $Res Function(DictionaryEntry) _then) = _$DictionaryEntryCopyWithImpl;
@useResult
$Res call({
 String word, String ipa, String hindiPronunciation, List<Sense> senses, List<BilingualPair> synonyms, List<BilingualPair> antonyms, List<WordForm> forms, bool isPhrase
});




}
/// @nodoc
class _$DictionaryEntryCopyWithImpl<$Res>
    implements $DictionaryEntryCopyWith<$Res> {
  _$DictionaryEntryCopyWithImpl(this._self, this._then);

  final DictionaryEntry _self;
  final $Res Function(DictionaryEntry) _then;

/// Create a copy of DictionaryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? word = null,Object? ipa = null,Object? hindiPronunciation = null,Object? senses = null,Object? synonyms = null,Object? antonyms = null,Object? forms = null,Object? isPhrase = null,}) {
  return _then(_self.copyWith(
word: null == word ? _self.word : word // ignore: cast_nullable_to_non_nullable
as String,ipa: null == ipa ? _self.ipa : ipa // ignore: cast_nullable_to_non_nullable
as String,hindiPronunciation: null == hindiPronunciation ? _self.hindiPronunciation : hindiPronunciation // ignore: cast_nullable_to_non_nullable
as String,senses: null == senses ? _self.senses : senses // ignore: cast_nullable_to_non_nullable
as List<Sense>,synonyms: null == synonyms ? _self.synonyms : synonyms // ignore: cast_nullable_to_non_nullable
as List<BilingualPair>,antonyms: null == antonyms ? _self.antonyms : antonyms // ignore: cast_nullable_to_non_nullable
as List<BilingualPair>,forms: null == forms ? _self.forms : forms // ignore: cast_nullable_to_non_nullable
as List<WordForm>,isPhrase: null == isPhrase ? _self.isPhrase : isPhrase // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DictionaryEntry].
extension DictionaryEntryPatterns on DictionaryEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DictionaryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DictionaryEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DictionaryEntry value)  $default,){
final _that = this;
switch (_that) {
case _DictionaryEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DictionaryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _DictionaryEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String word,  String ipa,  String hindiPronunciation,  List<Sense> senses,  List<BilingualPair> synonyms,  List<BilingualPair> antonyms,  List<WordForm> forms,  bool isPhrase)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DictionaryEntry() when $default != null:
return $default(_that.word,_that.ipa,_that.hindiPronunciation,_that.senses,_that.synonyms,_that.antonyms,_that.forms,_that.isPhrase);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String word,  String ipa,  String hindiPronunciation,  List<Sense> senses,  List<BilingualPair> synonyms,  List<BilingualPair> antonyms,  List<WordForm> forms,  bool isPhrase)  $default,) {final _that = this;
switch (_that) {
case _DictionaryEntry():
return $default(_that.word,_that.ipa,_that.hindiPronunciation,_that.senses,_that.synonyms,_that.antonyms,_that.forms,_that.isPhrase);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String word,  String ipa,  String hindiPronunciation,  List<Sense> senses,  List<BilingualPair> synonyms,  List<BilingualPair> antonyms,  List<WordForm> forms,  bool isPhrase)?  $default,) {final _that = this;
switch (_that) {
case _DictionaryEntry() when $default != null:
return $default(_that.word,_that.ipa,_that.hindiPronunciation,_that.senses,_that.synonyms,_that.antonyms,_that.forms,_that.isPhrase);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DictionaryEntry implements DictionaryEntry {
  const _DictionaryEntry({required this.word, required this.ipa, required this.hindiPronunciation, required final  List<Sense> senses, required final  List<BilingualPair> synonyms, required final  List<BilingualPair> antonyms, required final  List<WordForm> forms, required this.isPhrase}): _senses = senses,_synonyms = synonyms,_antonyms = antonyms,_forms = forms;
  factory _DictionaryEntry.fromJson(Map<String, dynamic> json) => _$DictionaryEntryFromJson(json);

@override final  String word;
@override final  String ipa;
@override final  String hindiPronunciation;
 final  List<Sense> _senses;
@override List<Sense> get senses {
  if (_senses is EqualUnmodifiableListView) return _senses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_senses);
}

 final  List<BilingualPair> _synonyms;
@override List<BilingualPair> get synonyms {
  if (_synonyms is EqualUnmodifiableListView) return _synonyms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_synonyms);
}

 final  List<BilingualPair> _antonyms;
@override List<BilingualPair> get antonyms {
  if (_antonyms is EqualUnmodifiableListView) return _antonyms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_antonyms);
}

 final  List<WordForm> _forms;
@override List<WordForm> get forms {
  if (_forms is EqualUnmodifiableListView) return _forms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_forms);
}

@override final  bool isPhrase;

/// Create a copy of DictionaryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DictionaryEntryCopyWith<_DictionaryEntry> get copyWith => __$DictionaryEntryCopyWithImpl<_DictionaryEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DictionaryEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DictionaryEntry&&(identical(other.word, word) || other.word == word)&&(identical(other.ipa, ipa) || other.ipa == ipa)&&(identical(other.hindiPronunciation, hindiPronunciation) || other.hindiPronunciation == hindiPronunciation)&&const DeepCollectionEquality().equals(other._senses, _senses)&&const DeepCollectionEquality().equals(other._synonyms, _synonyms)&&const DeepCollectionEquality().equals(other._antonyms, _antonyms)&&const DeepCollectionEquality().equals(other._forms, _forms)&&(identical(other.isPhrase, isPhrase) || other.isPhrase == isPhrase));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,word,ipa,hindiPronunciation,const DeepCollectionEquality().hash(_senses),const DeepCollectionEquality().hash(_synonyms),const DeepCollectionEquality().hash(_antonyms),const DeepCollectionEquality().hash(_forms),isPhrase);

@override
String toString() {
  return 'DictionaryEntry(word: $word, ipa: $ipa, hindiPronunciation: $hindiPronunciation, senses: $senses, synonyms: $synonyms, antonyms: $antonyms, forms: $forms, isPhrase: $isPhrase)';
}


}

/// @nodoc
abstract mixin class _$DictionaryEntryCopyWith<$Res> implements $DictionaryEntryCopyWith<$Res> {
  factory _$DictionaryEntryCopyWith(_DictionaryEntry value, $Res Function(_DictionaryEntry) _then) = __$DictionaryEntryCopyWithImpl;
@override @useResult
$Res call({
 String word, String ipa, String hindiPronunciation, List<Sense> senses, List<BilingualPair> synonyms, List<BilingualPair> antonyms, List<WordForm> forms, bool isPhrase
});




}
/// @nodoc
class __$DictionaryEntryCopyWithImpl<$Res>
    implements _$DictionaryEntryCopyWith<$Res> {
  __$DictionaryEntryCopyWithImpl(this._self, this._then);

  final _DictionaryEntry _self;
  final $Res Function(_DictionaryEntry) _then;

/// Create a copy of DictionaryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? word = null,Object? ipa = null,Object? hindiPronunciation = null,Object? senses = null,Object? synonyms = null,Object? antonyms = null,Object? forms = null,Object? isPhrase = null,}) {
  return _then(_DictionaryEntry(
word: null == word ? _self.word : word // ignore: cast_nullable_to_non_nullable
as String,ipa: null == ipa ? _self.ipa : ipa // ignore: cast_nullable_to_non_nullable
as String,hindiPronunciation: null == hindiPronunciation ? _self.hindiPronunciation : hindiPronunciation // ignore: cast_nullable_to_non_nullable
as String,senses: null == senses ? _self._senses : senses // ignore: cast_nullable_to_non_nullable
as List<Sense>,synonyms: null == synonyms ? _self._synonyms : synonyms // ignore: cast_nullable_to_non_nullable
as List<BilingualPair>,antonyms: null == antonyms ? _self._antonyms : antonyms // ignore: cast_nullable_to_non_nullable
as List<BilingualPair>,forms: null == forms ? _self._forms : forms // ignore: cast_nullable_to_non_nullable
as List<WordForm>,isPhrase: null == isPhrase ? _self.isPhrase : isPhrase // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Sense {

 int get index; String get partOfSpeech; String get meaning; String get definition; String? get styleLabel; List<BilingualPair> get examples;
/// Create a copy of Sense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SenseCopyWith<Sense> get copyWith => _$SenseCopyWithImpl<Sense>(this as Sense, _$identity);

  /// Serializes this Sense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Sense&&(identical(other.index, index) || other.index == index)&&(identical(other.partOfSpeech, partOfSpeech) || other.partOfSpeech == partOfSpeech)&&(identical(other.meaning, meaning) || other.meaning == meaning)&&(identical(other.definition, definition) || other.definition == definition)&&(identical(other.styleLabel, styleLabel) || other.styleLabel == styleLabel)&&const DeepCollectionEquality().equals(other.examples, examples));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,partOfSpeech,meaning,definition,styleLabel,const DeepCollectionEquality().hash(examples));

@override
String toString() {
  return 'Sense(index: $index, partOfSpeech: $partOfSpeech, meaning: $meaning, definition: $definition, styleLabel: $styleLabel, examples: $examples)';
}


}

/// @nodoc
abstract mixin class $SenseCopyWith<$Res>  {
  factory $SenseCopyWith(Sense value, $Res Function(Sense) _then) = _$SenseCopyWithImpl;
@useResult
$Res call({
 int index, String partOfSpeech, String meaning, String definition, String? styleLabel, List<BilingualPair> examples
});




}
/// @nodoc
class _$SenseCopyWithImpl<$Res>
    implements $SenseCopyWith<$Res> {
  _$SenseCopyWithImpl(this._self, this._then);

  final Sense _self;
  final $Res Function(Sense) _then;

/// Create a copy of Sense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? partOfSpeech = null,Object? meaning = null,Object? definition = null,Object? styleLabel = freezed,Object? examples = null,}) {
  return _then(_self.copyWith(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,partOfSpeech: null == partOfSpeech ? _self.partOfSpeech : partOfSpeech // ignore: cast_nullable_to_non_nullable
as String,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as String,styleLabel: freezed == styleLabel ? _self.styleLabel : styleLabel // ignore: cast_nullable_to_non_nullable
as String?,examples: null == examples ? _self.examples : examples // ignore: cast_nullable_to_non_nullable
as List<BilingualPair>,
  ));
}

}


/// Adds pattern-matching-related methods to [Sense].
extension SensePatterns on Sense {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Sense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Sense() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Sense value)  $default,){
final _that = this;
switch (_that) {
case _Sense():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Sense value)?  $default,){
final _that = this;
switch (_that) {
case _Sense() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  String partOfSpeech,  String meaning,  String definition,  String? styleLabel,  List<BilingualPair> examples)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Sense() when $default != null:
return $default(_that.index,_that.partOfSpeech,_that.meaning,_that.definition,_that.styleLabel,_that.examples);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  String partOfSpeech,  String meaning,  String definition,  String? styleLabel,  List<BilingualPair> examples)  $default,) {final _that = this;
switch (_that) {
case _Sense():
return $default(_that.index,_that.partOfSpeech,_that.meaning,_that.definition,_that.styleLabel,_that.examples);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  String partOfSpeech,  String meaning,  String definition,  String? styleLabel,  List<BilingualPair> examples)?  $default,) {final _that = this;
switch (_that) {
case _Sense() when $default != null:
return $default(_that.index,_that.partOfSpeech,_that.meaning,_that.definition,_that.styleLabel,_that.examples);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Sense implements Sense {
  const _Sense({required this.index, required this.partOfSpeech, required this.meaning, required this.definition, this.styleLabel, required final  List<BilingualPair> examples}): _examples = examples;
  factory _Sense.fromJson(Map<String, dynamic> json) => _$SenseFromJson(json);

@override final  int index;
@override final  String partOfSpeech;
@override final  String meaning;
@override final  String definition;
@override final  String? styleLabel;
 final  List<BilingualPair> _examples;
@override List<BilingualPair> get examples {
  if (_examples is EqualUnmodifiableListView) return _examples;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_examples);
}


/// Create a copy of Sense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SenseCopyWith<_Sense> get copyWith => __$SenseCopyWithImpl<_Sense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Sense&&(identical(other.index, index) || other.index == index)&&(identical(other.partOfSpeech, partOfSpeech) || other.partOfSpeech == partOfSpeech)&&(identical(other.meaning, meaning) || other.meaning == meaning)&&(identical(other.definition, definition) || other.definition == definition)&&(identical(other.styleLabel, styleLabel) || other.styleLabel == styleLabel)&&const DeepCollectionEquality().equals(other._examples, _examples));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,partOfSpeech,meaning,definition,styleLabel,const DeepCollectionEquality().hash(_examples));

@override
String toString() {
  return 'Sense(index: $index, partOfSpeech: $partOfSpeech, meaning: $meaning, definition: $definition, styleLabel: $styleLabel, examples: $examples)';
}


}

/// @nodoc
abstract mixin class _$SenseCopyWith<$Res> implements $SenseCopyWith<$Res> {
  factory _$SenseCopyWith(_Sense value, $Res Function(_Sense) _then) = __$SenseCopyWithImpl;
@override @useResult
$Res call({
 int index, String partOfSpeech, String meaning, String definition, String? styleLabel, List<BilingualPair> examples
});




}
/// @nodoc
class __$SenseCopyWithImpl<$Res>
    implements _$SenseCopyWith<$Res> {
  __$SenseCopyWithImpl(this._self, this._then);

  final _Sense _self;
  final $Res Function(_Sense) _then;

/// Create a copy of Sense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? partOfSpeech = null,Object? meaning = null,Object? definition = null,Object? styleLabel = freezed,Object? examples = null,}) {
  return _then(_Sense(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,partOfSpeech: null == partOfSpeech ? _self.partOfSpeech : partOfSpeech // ignore: cast_nullable_to_non_nullable
as String,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as String,styleLabel: freezed == styleLabel ? _self.styleLabel : styleLabel // ignore: cast_nullable_to_non_nullable
as String?,examples: null == examples ? _self._examples : examples // ignore: cast_nullable_to_non_nullable
as List<BilingualPair>,
  ));
}


}


/// @nodoc
mixin _$BilingualPair {

 String get en; String get hi;
/// Create a copy of BilingualPair
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BilingualPairCopyWith<BilingualPair> get copyWith => _$BilingualPairCopyWithImpl<BilingualPair>(this as BilingualPair, _$identity);

  /// Serializes this BilingualPair to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BilingualPair&&(identical(other.en, en) || other.en == en)&&(identical(other.hi, hi) || other.hi == hi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,en,hi);

@override
String toString() {
  return 'BilingualPair(en: $en, hi: $hi)';
}


}

/// @nodoc
abstract mixin class $BilingualPairCopyWith<$Res>  {
  factory $BilingualPairCopyWith(BilingualPair value, $Res Function(BilingualPair) _then) = _$BilingualPairCopyWithImpl;
@useResult
$Res call({
 String en, String hi
});




}
/// @nodoc
class _$BilingualPairCopyWithImpl<$Res>
    implements $BilingualPairCopyWith<$Res> {
  _$BilingualPairCopyWithImpl(this._self, this._then);

  final BilingualPair _self;
  final $Res Function(BilingualPair) _then;

/// Create a copy of BilingualPair
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? en = null,Object? hi = null,}) {
  return _then(_self.copyWith(
en: null == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String,hi: null == hi ? _self.hi : hi // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BilingualPair].
extension BilingualPairPatterns on BilingualPair {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BilingualPair value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BilingualPair() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BilingualPair value)  $default,){
final _that = this;
switch (_that) {
case _BilingualPair():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BilingualPair value)?  $default,){
final _that = this;
switch (_that) {
case _BilingualPair() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String en,  String hi)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BilingualPair() when $default != null:
return $default(_that.en,_that.hi);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String en,  String hi)  $default,) {final _that = this;
switch (_that) {
case _BilingualPair():
return $default(_that.en,_that.hi);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String en,  String hi)?  $default,) {final _that = this;
switch (_that) {
case _BilingualPair() when $default != null:
return $default(_that.en,_that.hi);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BilingualPair implements BilingualPair {
  const _BilingualPair({required this.en, required this.hi});
  factory _BilingualPair.fromJson(Map<String, dynamic> json) => _$BilingualPairFromJson(json);

@override final  String en;
@override final  String hi;

/// Create a copy of BilingualPair
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BilingualPairCopyWith<_BilingualPair> get copyWith => __$BilingualPairCopyWithImpl<_BilingualPair>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BilingualPairToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BilingualPair&&(identical(other.en, en) || other.en == en)&&(identical(other.hi, hi) || other.hi == hi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,en,hi);

@override
String toString() {
  return 'BilingualPair(en: $en, hi: $hi)';
}


}

/// @nodoc
abstract mixin class _$BilingualPairCopyWith<$Res> implements $BilingualPairCopyWith<$Res> {
  factory _$BilingualPairCopyWith(_BilingualPair value, $Res Function(_BilingualPair) _then) = __$BilingualPairCopyWithImpl;
@override @useResult
$Res call({
 String en, String hi
});




}
/// @nodoc
class __$BilingualPairCopyWithImpl<$Res>
    implements _$BilingualPairCopyWith<$Res> {
  __$BilingualPairCopyWithImpl(this._self, this._then);

  final _BilingualPair _self;
  final $Res Function(_BilingualPair) _then;

/// Create a copy of BilingualPair
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? en = null,Object? hi = null,}) {
  return _then(_BilingualPair(
en: null == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String,hi: null == hi ? _self.hi : hi // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WordForm {

 String get en; String get label; String get hi;
/// Create a copy of WordForm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WordFormCopyWith<WordForm> get copyWith => _$WordFormCopyWithImpl<WordForm>(this as WordForm, _$identity);

  /// Serializes this WordForm to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WordForm&&(identical(other.en, en) || other.en == en)&&(identical(other.label, label) || other.label == label)&&(identical(other.hi, hi) || other.hi == hi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,en,label,hi);

@override
String toString() {
  return 'WordForm(en: $en, label: $label, hi: $hi)';
}


}

/// @nodoc
abstract mixin class $WordFormCopyWith<$Res>  {
  factory $WordFormCopyWith(WordForm value, $Res Function(WordForm) _then) = _$WordFormCopyWithImpl;
@useResult
$Res call({
 String en, String label, String hi
});




}
/// @nodoc
class _$WordFormCopyWithImpl<$Res>
    implements $WordFormCopyWith<$Res> {
  _$WordFormCopyWithImpl(this._self, this._then);

  final WordForm _self;
  final $Res Function(WordForm) _then;

/// Create a copy of WordForm
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? en = null,Object? label = null,Object? hi = null,}) {
  return _then(_self.copyWith(
en: null == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,hi: null == hi ? _self.hi : hi // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WordForm].
extension WordFormPatterns on WordForm {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WordForm value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WordForm() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WordForm value)  $default,){
final _that = this;
switch (_that) {
case _WordForm():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WordForm value)?  $default,){
final _that = this;
switch (_that) {
case _WordForm() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String en,  String label,  String hi)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WordForm() when $default != null:
return $default(_that.en,_that.label,_that.hi);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String en,  String label,  String hi)  $default,) {final _that = this;
switch (_that) {
case _WordForm():
return $default(_that.en,_that.label,_that.hi);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String en,  String label,  String hi)?  $default,) {final _that = this;
switch (_that) {
case _WordForm() when $default != null:
return $default(_that.en,_that.label,_that.hi);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WordForm implements WordForm {
  const _WordForm({required this.en, required this.label, required this.hi});
  factory _WordForm.fromJson(Map<String, dynamic> json) => _$WordFormFromJson(json);

@override final  String en;
@override final  String label;
@override final  String hi;

/// Create a copy of WordForm
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WordFormCopyWith<_WordForm> get copyWith => __$WordFormCopyWithImpl<_WordForm>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WordFormToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WordForm&&(identical(other.en, en) || other.en == en)&&(identical(other.label, label) || other.label == label)&&(identical(other.hi, hi) || other.hi == hi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,en,label,hi);

@override
String toString() {
  return 'WordForm(en: $en, label: $label, hi: $hi)';
}


}

/// @nodoc
abstract mixin class _$WordFormCopyWith<$Res> implements $WordFormCopyWith<$Res> {
  factory _$WordFormCopyWith(_WordForm value, $Res Function(_WordForm) _then) = __$WordFormCopyWithImpl;
@override @useResult
$Res call({
 String en, String label, String hi
});




}
/// @nodoc
class __$WordFormCopyWithImpl<$Res>
    implements _$WordFormCopyWith<$Res> {
  __$WordFormCopyWithImpl(this._self, this._then);

  final _WordForm _self;
  final $Res Function(_WordForm) _then;

/// Create a copy of WordForm
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? en = null,Object? label = null,Object? hi = null,}) {
  return _then(_WordForm(
en: null == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,hi: null == hi ? _self.hi : hi // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ContextResult {

 int get senseIndex; String get meaning; String get note;
/// Create a copy of ContextResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContextResultCopyWith<ContextResult> get copyWith => _$ContextResultCopyWithImpl<ContextResult>(this as ContextResult, _$identity);

  /// Serializes this ContextResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContextResult&&(identical(other.senseIndex, senseIndex) || other.senseIndex == senseIndex)&&(identical(other.meaning, meaning) || other.meaning == meaning)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,senseIndex,meaning,note);

@override
String toString() {
  return 'ContextResult(senseIndex: $senseIndex, meaning: $meaning, note: $note)';
}


}

/// @nodoc
abstract mixin class $ContextResultCopyWith<$Res>  {
  factory $ContextResultCopyWith(ContextResult value, $Res Function(ContextResult) _then) = _$ContextResultCopyWithImpl;
@useResult
$Res call({
 int senseIndex, String meaning, String note
});




}
/// @nodoc
class _$ContextResultCopyWithImpl<$Res>
    implements $ContextResultCopyWith<$Res> {
  _$ContextResultCopyWithImpl(this._self, this._then);

  final ContextResult _self;
  final $Res Function(ContextResult) _then;

/// Create a copy of ContextResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? senseIndex = null,Object? meaning = null,Object? note = null,}) {
  return _then(_self.copyWith(
senseIndex: null == senseIndex ? _self.senseIndex : senseIndex // ignore: cast_nullable_to_non_nullable
as int,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ContextResult].
extension ContextResultPatterns on ContextResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContextResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContextResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContextResult value)  $default,){
final _that = this;
switch (_that) {
case _ContextResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContextResult value)?  $default,){
final _that = this;
switch (_that) {
case _ContextResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int senseIndex,  String meaning,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContextResult() when $default != null:
return $default(_that.senseIndex,_that.meaning,_that.note);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int senseIndex,  String meaning,  String note)  $default,) {final _that = this;
switch (_that) {
case _ContextResult():
return $default(_that.senseIndex,_that.meaning,_that.note);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int senseIndex,  String meaning,  String note)?  $default,) {final _that = this;
switch (_that) {
case _ContextResult() when $default != null:
return $default(_that.senseIndex,_that.meaning,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContextResult implements ContextResult {
  const _ContextResult({required this.senseIndex, required this.meaning, required this.note});
  factory _ContextResult.fromJson(Map<String, dynamic> json) => _$ContextResultFromJson(json);

@override final  int senseIndex;
@override final  String meaning;
@override final  String note;

/// Create a copy of ContextResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContextResultCopyWith<_ContextResult> get copyWith => __$ContextResultCopyWithImpl<_ContextResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContextResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContextResult&&(identical(other.senseIndex, senseIndex) || other.senseIndex == senseIndex)&&(identical(other.meaning, meaning) || other.meaning == meaning)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,senseIndex,meaning,note);

@override
String toString() {
  return 'ContextResult(senseIndex: $senseIndex, meaning: $meaning, note: $note)';
}


}

/// @nodoc
abstract mixin class _$ContextResultCopyWith<$Res> implements $ContextResultCopyWith<$Res> {
  factory _$ContextResultCopyWith(_ContextResult value, $Res Function(_ContextResult) _then) = __$ContextResultCopyWithImpl;
@override @useResult
$Res call({
 int senseIndex, String meaning, String note
});




}
/// @nodoc
class __$ContextResultCopyWithImpl<$Res>
    implements _$ContextResultCopyWith<$Res> {
  __$ContextResultCopyWithImpl(this._self, this._then);

  final _ContextResult _self;
  final $Res Function(_ContextResult) _then;

/// Create a copy of ContextResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? senseIndex = null,Object? meaning = null,Object? note = null,}) {
  return _then(_ContextResult(
senseIndex: null == senseIndex ? _self.senseIndex : senseIndex // ignore: cast_nullable_to_non_nullable
as int,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TranslationResult {

 String get source; String get hindi; String get simpleMeaning; List<TranslationResultDifficultWords> get difficultWords;
/// Create a copy of TranslationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TranslationResultCopyWith<TranslationResult> get copyWith => _$TranslationResultCopyWithImpl<TranslationResult>(this as TranslationResult, _$identity);

  /// Serializes this TranslationResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TranslationResult&&(identical(other.source, source) || other.source == source)&&(identical(other.hindi, hindi) || other.hindi == hindi)&&(identical(other.simpleMeaning, simpleMeaning) || other.simpleMeaning == simpleMeaning)&&const DeepCollectionEquality().equals(other.difficultWords, difficultWords));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,hindi,simpleMeaning,const DeepCollectionEquality().hash(difficultWords));

@override
String toString() {
  return 'TranslationResult(source: $source, hindi: $hindi, simpleMeaning: $simpleMeaning, difficultWords: $difficultWords)';
}


}

/// @nodoc
abstract mixin class $TranslationResultCopyWith<$Res>  {
  factory $TranslationResultCopyWith(TranslationResult value, $Res Function(TranslationResult) _then) = _$TranslationResultCopyWithImpl;
@useResult
$Res call({
 String source, String hindi, String simpleMeaning, List<TranslationResultDifficultWords> difficultWords
});




}
/// @nodoc
class _$TranslationResultCopyWithImpl<$Res>
    implements $TranslationResultCopyWith<$Res> {
  _$TranslationResultCopyWithImpl(this._self, this._then);

  final TranslationResult _self;
  final $Res Function(TranslationResult) _then;

/// Create a copy of TranslationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? hindi = null,Object? simpleMeaning = null,Object? difficultWords = null,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,hindi: null == hindi ? _self.hindi : hindi // ignore: cast_nullable_to_non_nullable
as String,simpleMeaning: null == simpleMeaning ? _self.simpleMeaning : simpleMeaning // ignore: cast_nullable_to_non_nullable
as String,difficultWords: null == difficultWords ? _self.difficultWords : difficultWords // ignore: cast_nullable_to_non_nullable
as List<TranslationResultDifficultWords>,
  ));
}

}


/// Adds pattern-matching-related methods to [TranslationResult].
extension TranslationResultPatterns on TranslationResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TranslationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TranslationResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TranslationResult value)  $default,){
final _that = this;
switch (_that) {
case _TranslationResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TranslationResult value)?  $default,){
final _that = this;
switch (_that) {
case _TranslationResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String source,  String hindi,  String simpleMeaning,  List<TranslationResultDifficultWords> difficultWords)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TranslationResult() when $default != null:
return $default(_that.source,_that.hindi,_that.simpleMeaning,_that.difficultWords);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String source,  String hindi,  String simpleMeaning,  List<TranslationResultDifficultWords> difficultWords)  $default,) {final _that = this;
switch (_that) {
case _TranslationResult():
return $default(_that.source,_that.hindi,_that.simpleMeaning,_that.difficultWords);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String source,  String hindi,  String simpleMeaning,  List<TranslationResultDifficultWords> difficultWords)?  $default,) {final _that = this;
switch (_that) {
case _TranslationResult() when $default != null:
return $default(_that.source,_that.hindi,_that.simpleMeaning,_that.difficultWords);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TranslationResult implements TranslationResult {
  const _TranslationResult({required this.source, required this.hindi, required this.simpleMeaning, required final  List<TranslationResultDifficultWords> difficultWords}): _difficultWords = difficultWords;
  factory _TranslationResult.fromJson(Map<String, dynamic> json) => _$TranslationResultFromJson(json);

@override final  String source;
@override final  String hindi;
@override final  String simpleMeaning;
 final  List<TranslationResultDifficultWords> _difficultWords;
@override List<TranslationResultDifficultWords> get difficultWords {
  if (_difficultWords is EqualUnmodifiableListView) return _difficultWords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_difficultWords);
}


/// Create a copy of TranslationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TranslationResultCopyWith<_TranslationResult> get copyWith => __$TranslationResultCopyWithImpl<_TranslationResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TranslationResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TranslationResult&&(identical(other.source, source) || other.source == source)&&(identical(other.hindi, hindi) || other.hindi == hindi)&&(identical(other.simpleMeaning, simpleMeaning) || other.simpleMeaning == simpleMeaning)&&const DeepCollectionEquality().equals(other._difficultWords, _difficultWords));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,hindi,simpleMeaning,const DeepCollectionEquality().hash(_difficultWords));

@override
String toString() {
  return 'TranslationResult(source: $source, hindi: $hindi, simpleMeaning: $simpleMeaning, difficultWords: $difficultWords)';
}


}

/// @nodoc
abstract mixin class _$TranslationResultCopyWith<$Res> implements $TranslationResultCopyWith<$Res> {
  factory _$TranslationResultCopyWith(_TranslationResult value, $Res Function(_TranslationResult) _then) = __$TranslationResultCopyWithImpl;
@override @useResult
$Res call({
 String source, String hindi, String simpleMeaning, List<TranslationResultDifficultWords> difficultWords
});




}
/// @nodoc
class __$TranslationResultCopyWithImpl<$Res>
    implements _$TranslationResultCopyWith<$Res> {
  __$TranslationResultCopyWithImpl(this._self, this._then);

  final _TranslationResult _self;
  final $Res Function(_TranslationResult) _then;

/// Create a copy of TranslationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? hindi = null,Object? simpleMeaning = null,Object? difficultWords = null,}) {
  return _then(_TranslationResult(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,hindi: null == hindi ? _self.hindi : hindi // ignore: cast_nullable_to_non_nullable
as String,simpleMeaning: null == simpleMeaning ? _self.simpleMeaning : simpleMeaning // ignore: cast_nullable_to_non_nullable
as String,difficultWords: null == difficultWords ? _self._difficultWords : difficultWords // ignore: cast_nullable_to_non_nullable
as List<TranslationResultDifficultWords>,
  ));
}


}


/// @nodoc
mixin _$TranslationResultDifficultWords {

 String get en; String get hi;
/// Create a copy of TranslationResultDifficultWords
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TranslationResultDifficultWordsCopyWith<TranslationResultDifficultWords> get copyWith => _$TranslationResultDifficultWordsCopyWithImpl<TranslationResultDifficultWords>(this as TranslationResultDifficultWords, _$identity);

  /// Serializes this TranslationResultDifficultWords to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TranslationResultDifficultWords&&(identical(other.en, en) || other.en == en)&&(identical(other.hi, hi) || other.hi == hi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,en,hi);

@override
String toString() {
  return 'TranslationResultDifficultWords(en: $en, hi: $hi)';
}


}

/// @nodoc
abstract mixin class $TranslationResultDifficultWordsCopyWith<$Res>  {
  factory $TranslationResultDifficultWordsCopyWith(TranslationResultDifficultWords value, $Res Function(TranslationResultDifficultWords) _then) = _$TranslationResultDifficultWordsCopyWithImpl;
@useResult
$Res call({
 String en, String hi
});




}
/// @nodoc
class _$TranslationResultDifficultWordsCopyWithImpl<$Res>
    implements $TranslationResultDifficultWordsCopyWith<$Res> {
  _$TranslationResultDifficultWordsCopyWithImpl(this._self, this._then);

  final TranslationResultDifficultWords _self;
  final $Res Function(TranslationResultDifficultWords) _then;

/// Create a copy of TranslationResultDifficultWords
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? en = null,Object? hi = null,}) {
  return _then(_self.copyWith(
en: null == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String,hi: null == hi ? _self.hi : hi // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TranslationResultDifficultWords].
extension TranslationResultDifficultWordsPatterns on TranslationResultDifficultWords {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TranslationResultDifficultWords value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TranslationResultDifficultWords() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TranslationResultDifficultWords value)  $default,){
final _that = this;
switch (_that) {
case _TranslationResultDifficultWords():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TranslationResultDifficultWords value)?  $default,){
final _that = this;
switch (_that) {
case _TranslationResultDifficultWords() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String en,  String hi)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TranslationResultDifficultWords() when $default != null:
return $default(_that.en,_that.hi);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String en,  String hi)  $default,) {final _that = this;
switch (_that) {
case _TranslationResultDifficultWords():
return $default(_that.en,_that.hi);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String en,  String hi)?  $default,) {final _that = this;
switch (_that) {
case _TranslationResultDifficultWords() when $default != null:
return $default(_that.en,_that.hi);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TranslationResultDifficultWords implements TranslationResultDifficultWords {
  const _TranslationResultDifficultWords({required this.en, required this.hi});
  factory _TranslationResultDifficultWords.fromJson(Map<String, dynamic> json) => _$TranslationResultDifficultWordsFromJson(json);

@override final  String en;
@override final  String hi;

/// Create a copy of TranslationResultDifficultWords
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TranslationResultDifficultWordsCopyWith<_TranslationResultDifficultWords> get copyWith => __$TranslationResultDifficultWordsCopyWithImpl<_TranslationResultDifficultWords>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TranslationResultDifficultWordsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TranslationResultDifficultWords&&(identical(other.en, en) || other.en == en)&&(identical(other.hi, hi) || other.hi == hi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,en,hi);

@override
String toString() {
  return 'TranslationResultDifficultWords(en: $en, hi: $hi)';
}


}

/// @nodoc
abstract mixin class _$TranslationResultDifficultWordsCopyWith<$Res> implements $TranslationResultDifficultWordsCopyWith<$Res> {
  factory _$TranslationResultDifficultWordsCopyWith(_TranslationResultDifficultWords value, $Res Function(_TranslationResultDifficultWords) _then) = __$TranslationResultDifficultWordsCopyWithImpl;
@override @useResult
$Res call({
 String en, String hi
});




}
/// @nodoc
class __$TranslationResultDifficultWordsCopyWithImpl<$Res>
    implements _$TranslationResultDifficultWordsCopyWith<$Res> {
  __$TranslationResultDifficultWordsCopyWithImpl(this._self, this._then);

  final _TranslationResultDifficultWords _self;
  final $Res Function(_TranslationResultDifficultWords) _then;

/// Create a copy of TranslationResultDifficultWords
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? en = null,Object? hi = null,}) {
  return _then(_TranslationResultDifficultWords(
en: null == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String,hi: null == hi ? _self.hi : hi // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PhraseMatch {

 String get phrase; String get lemma; int get start; int get tokenCount;
/// Create a copy of PhraseMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhraseMatchCopyWith<PhraseMatch> get copyWith => _$PhraseMatchCopyWithImpl<PhraseMatch>(this as PhraseMatch, _$identity);

  /// Serializes this PhraseMatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhraseMatch&&(identical(other.phrase, phrase) || other.phrase == phrase)&&(identical(other.lemma, lemma) || other.lemma == lemma)&&(identical(other.start, start) || other.start == start)&&(identical(other.tokenCount, tokenCount) || other.tokenCount == tokenCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phrase,lemma,start,tokenCount);

@override
String toString() {
  return 'PhraseMatch(phrase: $phrase, lemma: $lemma, start: $start, tokenCount: $tokenCount)';
}


}

/// @nodoc
abstract mixin class $PhraseMatchCopyWith<$Res>  {
  factory $PhraseMatchCopyWith(PhraseMatch value, $Res Function(PhraseMatch) _then) = _$PhraseMatchCopyWithImpl;
@useResult
$Res call({
 String phrase, String lemma, int start, int tokenCount
});




}
/// @nodoc
class _$PhraseMatchCopyWithImpl<$Res>
    implements $PhraseMatchCopyWith<$Res> {
  _$PhraseMatchCopyWithImpl(this._self, this._then);

  final PhraseMatch _self;
  final $Res Function(PhraseMatch) _then;

/// Create a copy of PhraseMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phrase = null,Object? lemma = null,Object? start = null,Object? tokenCount = null,}) {
  return _then(_self.copyWith(
phrase: null == phrase ? _self.phrase : phrase // ignore: cast_nullable_to_non_nullable
as String,lemma: null == lemma ? _self.lemma : lemma // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int,tokenCount: null == tokenCount ? _self.tokenCount : tokenCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PhraseMatch].
extension PhraseMatchPatterns on PhraseMatch {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PhraseMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PhraseMatch() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PhraseMatch value)  $default,){
final _that = this;
switch (_that) {
case _PhraseMatch():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PhraseMatch value)?  $default,){
final _that = this;
switch (_that) {
case _PhraseMatch() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String phrase,  String lemma,  int start,  int tokenCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PhraseMatch() when $default != null:
return $default(_that.phrase,_that.lemma,_that.start,_that.tokenCount);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String phrase,  String lemma,  int start,  int tokenCount)  $default,) {final _that = this;
switch (_that) {
case _PhraseMatch():
return $default(_that.phrase,_that.lemma,_that.start,_that.tokenCount);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String phrase,  String lemma,  int start,  int tokenCount)?  $default,) {final _that = this;
switch (_that) {
case _PhraseMatch() when $default != null:
return $default(_that.phrase,_that.lemma,_that.start,_that.tokenCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PhraseMatch implements PhraseMatch {
  const _PhraseMatch({required this.phrase, required this.lemma, required this.start, required this.tokenCount});
  factory _PhraseMatch.fromJson(Map<String, dynamic> json) => _$PhraseMatchFromJson(json);

@override final  String phrase;
@override final  String lemma;
@override final  int start;
@override final  int tokenCount;

/// Create a copy of PhraseMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PhraseMatchCopyWith<_PhraseMatch> get copyWith => __$PhraseMatchCopyWithImpl<_PhraseMatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PhraseMatchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PhraseMatch&&(identical(other.phrase, phrase) || other.phrase == phrase)&&(identical(other.lemma, lemma) || other.lemma == lemma)&&(identical(other.start, start) || other.start == start)&&(identical(other.tokenCount, tokenCount) || other.tokenCount == tokenCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phrase,lemma,start,tokenCount);

@override
String toString() {
  return 'PhraseMatch(phrase: $phrase, lemma: $lemma, start: $start, tokenCount: $tokenCount)';
}


}

/// @nodoc
abstract mixin class _$PhraseMatchCopyWith<$Res> implements $PhraseMatchCopyWith<$Res> {
  factory _$PhraseMatchCopyWith(_PhraseMatch value, $Res Function(_PhraseMatch) _then) = __$PhraseMatchCopyWithImpl;
@override @useResult
$Res call({
 String phrase, String lemma, int start, int tokenCount
});




}
/// @nodoc
class __$PhraseMatchCopyWithImpl<$Res>
    implements _$PhraseMatchCopyWith<$Res> {
  __$PhraseMatchCopyWithImpl(this._self, this._then);

  final _PhraseMatch _self;
  final $Res Function(_PhraseMatch) _then;

/// Create a copy of PhraseMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phrase = null,Object? lemma = null,Object? start = null,Object? tokenCount = null,}) {
  return _then(_PhraseMatch(
phrase: null == phrase ? _self.phrase : phrase // ignore: cast_nullable_to_non_nullable
as String,lemma: null == lemma ? _self.lemma : lemma // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int,tokenCount: null == tokenCount ? _self.tokenCount : tokenCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$RelatedPhrase {

 String get phrase; RelatedPhraseKind get kind; String get partOfSpeech; String get meaning;
/// Create a copy of RelatedPhrase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelatedPhraseCopyWith<RelatedPhrase> get copyWith => _$RelatedPhraseCopyWithImpl<RelatedPhrase>(this as RelatedPhrase, _$identity);

  /// Serializes this RelatedPhrase to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelatedPhrase&&(identical(other.phrase, phrase) || other.phrase == phrase)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.partOfSpeech, partOfSpeech) || other.partOfSpeech == partOfSpeech)&&(identical(other.meaning, meaning) || other.meaning == meaning));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phrase,kind,partOfSpeech,meaning);

@override
String toString() {
  return 'RelatedPhrase(phrase: $phrase, kind: $kind, partOfSpeech: $partOfSpeech, meaning: $meaning)';
}


}

/// @nodoc
abstract mixin class $RelatedPhraseCopyWith<$Res>  {
  factory $RelatedPhraseCopyWith(RelatedPhrase value, $Res Function(RelatedPhrase) _then) = _$RelatedPhraseCopyWithImpl;
@useResult
$Res call({
 String phrase, RelatedPhraseKind kind, String partOfSpeech, String meaning
});




}
/// @nodoc
class _$RelatedPhraseCopyWithImpl<$Res>
    implements $RelatedPhraseCopyWith<$Res> {
  _$RelatedPhraseCopyWithImpl(this._self, this._then);

  final RelatedPhrase _self;
  final $Res Function(RelatedPhrase) _then;

/// Create a copy of RelatedPhrase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phrase = null,Object? kind = null,Object? partOfSpeech = null,Object? meaning = null,}) {
  return _then(_self.copyWith(
phrase: null == phrase ? _self.phrase : phrase // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RelatedPhraseKind,partOfSpeech: null == partOfSpeech ? _self.partOfSpeech : partOfSpeech // ignore: cast_nullable_to_non_nullable
as String,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RelatedPhrase].
extension RelatedPhrasePatterns on RelatedPhrase {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RelatedPhrase value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RelatedPhrase() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RelatedPhrase value)  $default,){
final _that = this;
switch (_that) {
case _RelatedPhrase():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RelatedPhrase value)?  $default,){
final _that = this;
switch (_that) {
case _RelatedPhrase() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String phrase,  RelatedPhraseKind kind,  String partOfSpeech,  String meaning)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RelatedPhrase() when $default != null:
return $default(_that.phrase,_that.kind,_that.partOfSpeech,_that.meaning);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String phrase,  RelatedPhraseKind kind,  String partOfSpeech,  String meaning)  $default,) {final _that = this;
switch (_that) {
case _RelatedPhrase():
return $default(_that.phrase,_that.kind,_that.partOfSpeech,_that.meaning);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String phrase,  RelatedPhraseKind kind,  String partOfSpeech,  String meaning)?  $default,) {final _that = this;
switch (_that) {
case _RelatedPhrase() when $default != null:
return $default(_that.phrase,_that.kind,_that.partOfSpeech,_that.meaning);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RelatedPhrase implements RelatedPhrase {
  const _RelatedPhrase({required this.phrase, required this.kind, required this.partOfSpeech, required this.meaning});
  factory _RelatedPhrase.fromJson(Map<String, dynamic> json) => _$RelatedPhraseFromJson(json);

@override final  String phrase;
@override final  RelatedPhraseKind kind;
@override final  String partOfSpeech;
@override final  String meaning;

/// Create a copy of RelatedPhrase
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RelatedPhraseCopyWith<_RelatedPhrase> get copyWith => __$RelatedPhraseCopyWithImpl<_RelatedPhrase>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RelatedPhraseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RelatedPhrase&&(identical(other.phrase, phrase) || other.phrase == phrase)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.partOfSpeech, partOfSpeech) || other.partOfSpeech == partOfSpeech)&&(identical(other.meaning, meaning) || other.meaning == meaning));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phrase,kind,partOfSpeech,meaning);

@override
String toString() {
  return 'RelatedPhrase(phrase: $phrase, kind: $kind, partOfSpeech: $partOfSpeech, meaning: $meaning)';
}


}

/// @nodoc
abstract mixin class _$RelatedPhraseCopyWith<$Res> implements $RelatedPhraseCopyWith<$Res> {
  factory _$RelatedPhraseCopyWith(_RelatedPhrase value, $Res Function(_RelatedPhrase) _then) = __$RelatedPhraseCopyWithImpl;
@override @useResult
$Res call({
 String phrase, RelatedPhraseKind kind, String partOfSpeech, String meaning
});




}
/// @nodoc
class __$RelatedPhraseCopyWithImpl<$Res>
    implements _$RelatedPhraseCopyWith<$Res> {
  __$RelatedPhraseCopyWithImpl(this._self, this._then);

  final _RelatedPhrase _self;
  final $Res Function(_RelatedPhrase) _then;

/// Create a copy of RelatedPhrase
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phrase = null,Object? kind = null,Object? partOfSpeech = null,Object? meaning = null,}) {
  return _then(_RelatedPhrase(
phrase: null == phrase ? _self.phrase : phrase // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RelatedPhraseKind,partOfSpeech: null == partOfSpeech ? _self.partOfSpeech : partOfSpeech // ignore: cast_nullable_to_non_nullable
as String,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GrammarNote {

 String get source; String get shape; List<GrammarNotePoints> get points;
/// Create a copy of GrammarNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrammarNoteCopyWith<GrammarNote> get copyWith => _$GrammarNoteCopyWithImpl<GrammarNote>(this as GrammarNote, _$identity);

  /// Serializes this GrammarNote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrammarNote&&(identical(other.source, source) || other.source == source)&&(identical(other.shape, shape) || other.shape == shape)&&const DeepCollectionEquality().equals(other.points, points));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,shape,const DeepCollectionEquality().hash(points));

@override
String toString() {
  return 'GrammarNote(source: $source, shape: $shape, points: $points)';
}


}

/// @nodoc
abstract mixin class $GrammarNoteCopyWith<$Res>  {
  factory $GrammarNoteCopyWith(GrammarNote value, $Res Function(GrammarNote) _then) = _$GrammarNoteCopyWithImpl;
@useResult
$Res call({
 String source, String shape, List<GrammarNotePoints> points
});




}
/// @nodoc
class _$GrammarNoteCopyWithImpl<$Res>
    implements $GrammarNoteCopyWith<$Res> {
  _$GrammarNoteCopyWithImpl(this._self, this._then);

  final GrammarNote _self;
  final $Res Function(GrammarNote) _then;

/// Create a copy of GrammarNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? shape = null,Object? points = null,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<GrammarNotePoints>,
  ));
}

}


/// Adds pattern-matching-related methods to [GrammarNote].
extension GrammarNotePatterns on GrammarNote {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrammarNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrammarNote() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrammarNote value)  $default,){
final _that = this;
switch (_that) {
case _GrammarNote():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrammarNote value)?  $default,){
final _that = this;
switch (_that) {
case _GrammarNote() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String source,  String shape,  List<GrammarNotePoints> points)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrammarNote() when $default != null:
return $default(_that.source,_that.shape,_that.points);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String source,  String shape,  List<GrammarNotePoints> points)  $default,) {final _that = this;
switch (_that) {
case _GrammarNote():
return $default(_that.source,_that.shape,_that.points);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String source,  String shape,  List<GrammarNotePoints> points)?  $default,) {final _that = this;
switch (_that) {
case _GrammarNote() when $default != null:
return $default(_that.source,_that.shape,_that.points);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GrammarNote implements GrammarNote {
  const _GrammarNote({required this.source, required this.shape, required final  List<GrammarNotePoints> points}): _points = points;
  factory _GrammarNote.fromJson(Map<String, dynamic> json) => _$GrammarNoteFromJson(json);

@override final  String source;
@override final  String shape;
 final  List<GrammarNotePoints> _points;
@override List<GrammarNotePoints> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}


/// Create a copy of GrammarNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrammarNoteCopyWith<_GrammarNote> get copyWith => __$GrammarNoteCopyWithImpl<_GrammarNote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GrammarNoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrammarNote&&(identical(other.source, source) || other.source == source)&&(identical(other.shape, shape) || other.shape == shape)&&const DeepCollectionEquality().equals(other._points, _points));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,shape,const DeepCollectionEquality().hash(_points));

@override
String toString() {
  return 'GrammarNote(source: $source, shape: $shape, points: $points)';
}


}

/// @nodoc
abstract mixin class _$GrammarNoteCopyWith<$Res> implements $GrammarNoteCopyWith<$Res> {
  factory _$GrammarNoteCopyWith(_GrammarNote value, $Res Function(_GrammarNote) _then) = __$GrammarNoteCopyWithImpl;
@override @useResult
$Res call({
 String source, String shape, List<GrammarNotePoints> points
});




}
/// @nodoc
class __$GrammarNoteCopyWithImpl<$Res>
    implements _$GrammarNoteCopyWith<$Res> {
  __$GrammarNoteCopyWithImpl(this._self, this._then);

  final _GrammarNote _self;
  final $Res Function(_GrammarNote) _then;

/// Create a copy of GrammarNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? shape = null,Object? points = null,}) {
  return _then(_GrammarNote(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<GrammarNotePoints>,
  ));
}


}


/// @nodoc
mixin _$GrammarNotePoints {

 String get part; String get label; String get note;
/// Create a copy of GrammarNotePoints
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrammarNotePointsCopyWith<GrammarNotePoints> get copyWith => _$GrammarNotePointsCopyWithImpl<GrammarNotePoints>(this as GrammarNotePoints, _$identity);

  /// Serializes this GrammarNotePoints to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrammarNotePoints&&(identical(other.part, part) || other.part == part)&&(identical(other.label, label) || other.label == label)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,part,label,note);

@override
String toString() {
  return 'GrammarNotePoints(part: $part, label: $label, note: $note)';
}


}

/// @nodoc
abstract mixin class $GrammarNotePointsCopyWith<$Res>  {
  factory $GrammarNotePointsCopyWith(GrammarNotePoints value, $Res Function(GrammarNotePoints) _then) = _$GrammarNotePointsCopyWithImpl;
@useResult
$Res call({
 String part, String label, String note
});




}
/// @nodoc
class _$GrammarNotePointsCopyWithImpl<$Res>
    implements $GrammarNotePointsCopyWith<$Res> {
  _$GrammarNotePointsCopyWithImpl(this._self, this._then);

  final GrammarNotePoints _self;
  final $Res Function(GrammarNotePoints) _then;

/// Create a copy of GrammarNotePoints
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? part = null,Object? label = null,Object? note = null,}) {
  return _then(_self.copyWith(
part: null == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GrammarNotePoints].
extension GrammarNotePointsPatterns on GrammarNotePoints {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrammarNotePoints value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrammarNotePoints() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrammarNotePoints value)  $default,){
final _that = this;
switch (_that) {
case _GrammarNotePoints():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrammarNotePoints value)?  $default,){
final _that = this;
switch (_that) {
case _GrammarNotePoints() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String part,  String label,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrammarNotePoints() when $default != null:
return $default(_that.part,_that.label,_that.note);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String part,  String label,  String note)  $default,) {final _that = this;
switch (_that) {
case _GrammarNotePoints():
return $default(_that.part,_that.label,_that.note);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String part,  String label,  String note)?  $default,) {final _that = this;
switch (_that) {
case _GrammarNotePoints() when $default != null:
return $default(_that.part,_that.label,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GrammarNotePoints implements GrammarNotePoints {
  const _GrammarNotePoints({required this.part, required this.label, required this.note});
  factory _GrammarNotePoints.fromJson(Map<String, dynamic> json) => _$GrammarNotePointsFromJson(json);

@override final  String part;
@override final  String label;
@override final  String note;

/// Create a copy of GrammarNotePoints
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrammarNotePointsCopyWith<_GrammarNotePoints> get copyWith => __$GrammarNotePointsCopyWithImpl<_GrammarNotePoints>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GrammarNotePointsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrammarNotePoints&&(identical(other.part, part) || other.part == part)&&(identical(other.label, label) || other.label == label)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,part,label,note);

@override
String toString() {
  return 'GrammarNotePoints(part: $part, label: $label, note: $note)';
}


}

/// @nodoc
abstract mixin class _$GrammarNotePointsCopyWith<$Res> implements $GrammarNotePointsCopyWith<$Res> {
  factory _$GrammarNotePointsCopyWith(_GrammarNotePoints value, $Res Function(_GrammarNotePoints) _then) = __$GrammarNotePointsCopyWithImpl;
@override @useResult
$Res call({
 String part, String label, String note
});




}
/// @nodoc
class __$GrammarNotePointsCopyWithImpl<$Res>
    implements _$GrammarNotePointsCopyWith<$Res> {
  __$GrammarNotePointsCopyWithImpl(this._self, this._then);

  final _GrammarNotePoints _self;
  final $Res Function(_GrammarNotePoints) _then;

/// Create a copy of GrammarNotePoints
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? part = null,Object? label = null,Object? note = null,}) {
  return _then(_GrammarNotePoints(
part: null == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PassageSummary {

 String get summary; List<String> get points; List<PassageSummaryPeople>? get people;
/// Create a copy of PassageSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PassageSummaryCopyWith<PassageSummary> get copyWith => _$PassageSummaryCopyWithImpl<PassageSummary>(this as PassageSummary, _$identity);

  /// Serializes this PassageSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PassageSummary&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.points, points)&&const DeepCollectionEquality().equals(other.people, people));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,summary,const DeepCollectionEquality().hash(points),const DeepCollectionEquality().hash(people));

@override
String toString() {
  return 'PassageSummary(summary: $summary, points: $points, people: $people)';
}


}

/// @nodoc
abstract mixin class $PassageSummaryCopyWith<$Res>  {
  factory $PassageSummaryCopyWith(PassageSummary value, $Res Function(PassageSummary) _then) = _$PassageSummaryCopyWithImpl;
@useResult
$Res call({
 String summary, List<String> points, List<PassageSummaryPeople>? people
});




}
/// @nodoc
class _$PassageSummaryCopyWithImpl<$Res>
    implements $PassageSummaryCopyWith<$Res> {
  _$PassageSummaryCopyWithImpl(this._self, this._then);

  final PassageSummary _self;
  final $Res Function(PassageSummary) _then;

/// Create a copy of PassageSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summary = null,Object? points = null,Object? people = freezed,}) {
  return _then(_self.copyWith(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<String>,people: freezed == people ? _self.people : people // ignore: cast_nullable_to_non_nullable
as List<PassageSummaryPeople>?,
  ));
}

}


/// Adds pattern-matching-related methods to [PassageSummary].
extension PassageSummaryPatterns on PassageSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PassageSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PassageSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PassageSummary value)  $default,){
final _that = this;
switch (_that) {
case _PassageSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PassageSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PassageSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String summary,  List<String> points,  List<PassageSummaryPeople>? people)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PassageSummary() when $default != null:
return $default(_that.summary,_that.points,_that.people);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String summary,  List<String> points,  List<PassageSummaryPeople>? people)  $default,) {final _that = this;
switch (_that) {
case _PassageSummary():
return $default(_that.summary,_that.points,_that.people);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String summary,  List<String> points,  List<PassageSummaryPeople>? people)?  $default,) {final _that = this;
switch (_that) {
case _PassageSummary() when $default != null:
return $default(_that.summary,_that.points,_that.people);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PassageSummary implements PassageSummary {
  const _PassageSummary({required this.summary, required final  List<String> points, final  List<PassageSummaryPeople>? people}): _points = points,_people = people;
  factory _PassageSummary.fromJson(Map<String, dynamic> json) => _$PassageSummaryFromJson(json);

@override final  String summary;
 final  List<String> _points;
@override List<String> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}

 final  List<PassageSummaryPeople>? _people;
@override List<PassageSummaryPeople>? get people {
  final value = _people;
  if (value == null) return null;
  if (_people is EqualUnmodifiableListView) return _people;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of PassageSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PassageSummaryCopyWith<_PassageSummary> get copyWith => __$PassageSummaryCopyWithImpl<_PassageSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PassageSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PassageSummary&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._points, _points)&&const DeepCollectionEquality().equals(other._people, _people));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,summary,const DeepCollectionEquality().hash(_points),const DeepCollectionEquality().hash(_people));

@override
String toString() {
  return 'PassageSummary(summary: $summary, points: $points, people: $people)';
}


}

/// @nodoc
abstract mixin class _$PassageSummaryCopyWith<$Res> implements $PassageSummaryCopyWith<$Res> {
  factory _$PassageSummaryCopyWith(_PassageSummary value, $Res Function(_PassageSummary) _then) = __$PassageSummaryCopyWithImpl;
@override @useResult
$Res call({
 String summary, List<String> points, List<PassageSummaryPeople>? people
});




}
/// @nodoc
class __$PassageSummaryCopyWithImpl<$Res>
    implements _$PassageSummaryCopyWith<$Res> {
  __$PassageSummaryCopyWithImpl(this._self, this._then);

  final _PassageSummary _self;
  final $Res Function(_PassageSummary) _then;

/// Create a copy of PassageSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summary = null,Object? points = null,Object? people = freezed,}) {
  return _then(_PassageSummary(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<String>,people: freezed == people ? _self._people : people // ignore: cast_nullable_to_non_nullable
as List<PassageSummaryPeople>?,
  ));
}


}


/// @nodoc
mixin _$PassageSummaryPeople {

 String get name; String get who;
/// Create a copy of PassageSummaryPeople
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PassageSummaryPeopleCopyWith<PassageSummaryPeople> get copyWith => _$PassageSummaryPeopleCopyWithImpl<PassageSummaryPeople>(this as PassageSummaryPeople, _$identity);

  /// Serializes this PassageSummaryPeople to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PassageSummaryPeople&&(identical(other.name, name) || other.name == name)&&(identical(other.who, who) || other.who == who));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,who);

@override
String toString() {
  return 'PassageSummaryPeople(name: $name, who: $who)';
}


}

/// @nodoc
abstract mixin class $PassageSummaryPeopleCopyWith<$Res>  {
  factory $PassageSummaryPeopleCopyWith(PassageSummaryPeople value, $Res Function(PassageSummaryPeople) _then) = _$PassageSummaryPeopleCopyWithImpl;
@useResult
$Res call({
 String name, String who
});




}
/// @nodoc
class _$PassageSummaryPeopleCopyWithImpl<$Res>
    implements $PassageSummaryPeopleCopyWith<$Res> {
  _$PassageSummaryPeopleCopyWithImpl(this._self, this._then);

  final PassageSummaryPeople _self;
  final $Res Function(PassageSummaryPeople) _then;

/// Create a copy of PassageSummaryPeople
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? who = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,who: null == who ? _self.who : who // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PassageSummaryPeople].
extension PassageSummaryPeoplePatterns on PassageSummaryPeople {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PassageSummaryPeople value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PassageSummaryPeople() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PassageSummaryPeople value)  $default,){
final _that = this;
switch (_that) {
case _PassageSummaryPeople():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PassageSummaryPeople value)?  $default,){
final _that = this;
switch (_that) {
case _PassageSummaryPeople() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String who)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PassageSummaryPeople() when $default != null:
return $default(_that.name,_that.who);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String who)  $default,) {final _that = this;
switch (_that) {
case _PassageSummaryPeople():
return $default(_that.name,_that.who);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String who)?  $default,) {final _that = this;
switch (_that) {
case _PassageSummaryPeople() when $default != null:
return $default(_that.name,_that.who);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PassageSummaryPeople implements PassageSummaryPeople {
  const _PassageSummaryPeople({required this.name, required this.who});
  factory _PassageSummaryPeople.fromJson(Map<String, dynamic> json) => _$PassageSummaryPeopleFromJson(json);

@override final  String name;
@override final  String who;

/// Create a copy of PassageSummaryPeople
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PassageSummaryPeopleCopyWith<_PassageSummaryPeople> get copyWith => __$PassageSummaryPeopleCopyWithImpl<_PassageSummaryPeople>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PassageSummaryPeopleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PassageSummaryPeople&&(identical(other.name, name) || other.name == name)&&(identical(other.who, who) || other.who == who));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,who);

@override
String toString() {
  return 'PassageSummaryPeople(name: $name, who: $who)';
}


}

/// @nodoc
abstract mixin class _$PassageSummaryPeopleCopyWith<$Res> implements $PassageSummaryPeopleCopyWith<$Res> {
  factory _$PassageSummaryPeopleCopyWith(_PassageSummaryPeople value, $Res Function(_PassageSummaryPeople) _then) = __$PassageSummaryPeopleCopyWithImpl;
@override @useResult
$Res call({
 String name, String who
});




}
/// @nodoc
class __$PassageSummaryPeopleCopyWithImpl<$Res>
    implements _$PassageSummaryPeopleCopyWith<$Res> {
  __$PassageSummaryPeopleCopyWithImpl(this._self, this._then);

  final _PassageSummaryPeople _self;
  final $Res Function(_PassageSummaryPeople) _then;

/// Create a copy of PassageSummaryPeople
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? who = null,}) {
  return _then(_PassageSummaryPeople(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,who: null == who ? _self.who : who // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$EnglishDraft {

 String get english; List<EnglishDraftVocab> get vocab; List<EnglishDraftAlternatives> get alternatives;
/// Create a copy of EnglishDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnglishDraftCopyWith<EnglishDraft> get copyWith => _$EnglishDraftCopyWithImpl<EnglishDraft>(this as EnglishDraft, _$identity);

  /// Serializes this EnglishDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnglishDraft&&(identical(other.english, english) || other.english == english)&&const DeepCollectionEquality().equals(other.vocab, vocab)&&const DeepCollectionEquality().equals(other.alternatives, alternatives));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,english,const DeepCollectionEquality().hash(vocab),const DeepCollectionEquality().hash(alternatives));

@override
String toString() {
  return 'EnglishDraft(english: $english, vocab: $vocab, alternatives: $alternatives)';
}


}

/// @nodoc
abstract mixin class $EnglishDraftCopyWith<$Res>  {
  factory $EnglishDraftCopyWith(EnglishDraft value, $Res Function(EnglishDraft) _then) = _$EnglishDraftCopyWithImpl;
@useResult
$Res call({
 String english, List<EnglishDraftVocab> vocab, List<EnglishDraftAlternatives> alternatives
});




}
/// @nodoc
class _$EnglishDraftCopyWithImpl<$Res>
    implements $EnglishDraftCopyWith<$Res> {
  _$EnglishDraftCopyWithImpl(this._self, this._then);

  final EnglishDraft _self;
  final $Res Function(EnglishDraft) _then;

/// Create a copy of EnglishDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? english = null,Object? vocab = null,Object? alternatives = null,}) {
  return _then(_self.copyWith(
english: null == english ? _self.english : english // ignore: cast_nullable_to_non_nullable
as String,vocab: null == vocab ? _self.vocab : vocab // ignore: cast_nullable_to_non_nullable
as List<EnglishDraftVocab>,alternatives: null == alternatives ? _self.alternatives : alternatives // ignore: cast_nullable_to_non_nullable
as List<EnglishDraftAlternatives>,
  ));
}

}


/// Adds pattern-matching-related methods to [EnglishDraft].
extension EnglishDraftPatterns on EnglishDraft {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnglishDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnglishDraft() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnglishDraft value)  $default,){
final _that = this;
switch (_that) {
case _EnglishDraft():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnglishDraft value)?  $default,){
final _that = this;
switch (_that) {
case _EnglishDraft() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String english,  List<EnglishDraftVocab> vocab,  List<EnglishDraftAlternatives> alternatives)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnglishDraft() when $default != null:
return $default(_that.english,_that.vocab,_that.alternatives);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String english,  List<EnglishDraftVocab> vocab,  List<EnglishDraftAlternatives> alternatives)  $default,) {final _that = this;
switch (_that) {
case _EnglishDraft():
return $default(_that.english,_that.vocab,_that.alternatives);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String english,  List<EnglishDraftVocab> vocab,  List<EnglishDraftAlternatives> alternatives)?  $default,) {final _that = this;
switch (_that) {
case _EnglishDraft() when $default != null:
return $default(_that.english,_that.vocab,_that.alternatives);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnglishDraft implements EnglishDraft {
  const _EnglishDraft({required this.english, required final  List<EnglishDraftVocab> vocab, required final  List<EnglishDraftAlternatives> alternatives}): _vocab = vocab,_alternatives = alternatives;
  factory _EnglishDraft.fromJson(Map<String, dynamic> json) => _$EnglishDraftFromJson(json);

@override final  String english;
 final  List<EnglishDraftVocab> _vocab;
@override List<EnglishDraftVocab> get vocab {
  if (_vocab is EqualUnmodifiableListView) return _vocab;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_vocab);
}

 final  List<EnglishDraftAlternatives> _alternatives;
@override List<EnglishDraftAlternatives> get alternatives {
  if (_alternatives is EqualUnmodifiableListView) return _alternatives;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alternatives);
}


/// Create a copy of EnglishDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnglishDraftCopyWith<_EnglishDraft> get copyWith => __$EnglishDraftCopyWithImpl<_EnglishDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnglishDraftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnglishDraft&&(identical(other.english, english) || other.english == english)&&const DeepCollectionEquality().equals(other._vocab, _vocab)&&const DeepCollectionEquality().equals(other._alternatives, _alternatives));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,english,const DeepCollectionEquality().hash(_vocab),const DeepCollectionEquality().hash(_alternatives));

@override
String toString() {
  return 'EnglishDraft(english: $english, vocab: $vocab, alternatives: $alternatives)';
}


}

/// @nodoc
abstract mixin class _$EnglishDraftCopyWith<$Res> implements $EnglishDraftCopyWith<$Res> {
  factory _$EnglishDraftCopyWith(_EnglishDraft value, $Res Function(_EnglishDraft) _then) = __$EnglishDraftCopyWithImpl;
@override @useResult
$Res call({
 String english, List<EnglishDraftVocab> vocab, List<EnglishDraftAlternatives> alternatives
});




}
/// @nodoc
class __$EnglishDraftCopyWithImpl<$Res>
    implements _$EnglishDraftCopyWith<$Res> {
  __$EnglishDraftCopyWithImpl(this._self, this._then);

  final _EnglishDraft _self;
  final $Res Function(_EnglishDraft) _then;

/// Create a copy of EnglishDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? english = null,Object? vocab = null,Object? alternatives = null,}) {
  return _then(_EnglishDraft(
english: null == english ? _self.english : english // ignore: cast_nullable_to_non_nullable
as String,vocab: null == vocab ? _self._vocab : vocab // ignore: cast_nullable_to_non_nullable
as List<EnglishDraftVocab>,alternatives: null == alternatives ? _self._alternatives : alternatives // ignore: cast_nullable_to_non_nullable
as List<EnglishDraftAlternatives>,
  ));
}


}


/// @nodoc
mixin _$EnglishDraftVocab {

 String get en; String get hi;
/// Create a copy of EnglishDraftVocab
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnglishDraftVocabCopyWith<EnglishDraftVocab> get copyWith => _$EnglishDraftVocabCopyWithImpl<EnglishDraftVocab>(this as EnglishDraftVocab, _$identity);

  /// Serializes this EnglishDraftVocab to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnglishDraftVocab&&(identical(other.en, en) || other.en == en)&&(identical(other.hi, hi) || other.hi == hi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,en,hi);

@override
String toString() {
  return 'EnglishDraftVocab(en: $en, hi: $hi)';
}


}

/// @nodoc
abstract mixin class $EnglishDraftVocabCopyWith<$Res>  {
  factory $EnglishDraftVocabCopyWith(EnglishDraftVocab value, $Res Function(EnglishDraftVocab) _then) = _$EnglishDraftVocabCopyWithImpl;
@useResult
$Res call({
 String en, String hi
});




}
/// @nodoc
class _$EnglishDraftVocabCopyWithImpl<$Res>
    implements $EnglishDraftVocabCopyWith<$Res> {
  _$EnglishDraftVocabCopyWithImpl(this._self, this._then);

  final EnglishDraftVocab _self;
  final $Res Function(EnglishDraftVocab) _then;

/// Create a copy of EnglishDraftVocab
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? en = null,Object? hi = null,}) {
  return _then(_self.copyWith(
en: null == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String,hi: null == hi ? _self.hi : hi // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EnglishDraftVocab].
extension EnglishDraftVocabPatterns on EnglishDraftVocab {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnglishDraftVocab value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnglishDraftVocab() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnglishDraftVocab value)  $default,){
final _that = this;
switch (_that) {
case _EnglishDraftVocab():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnglishDraftVocab value)?  $default,){
final _that = this;
switch (_that) {
case _EnglishDraftVocab() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String en,  String hi)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnglishDraftVocab() when $default != null:
return $default(_that.en,_that.hi);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String en,  String hi)  $default,) {final _that = this;
switch (_that) {
case _EnglishDraftVocab():
return $default(_that.en,_that.hi);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String en,  String hi)?  $default,) {final _that = this;
switch (_that) {
case _EnglishDraftVocab() when $default != null:
return $default(_that.en,_that.hi);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnglishDraftVocab implements EnglishDraftVocab {
  const _EnglishDraftVocab({required this.en, required this.hi});
  factory _EnglishDraftVocab.fromJson(Map<String, dynamic> json) => _$EnglishDraftVocabFromJson(json);

@override final  String en;
@override final  String hi;

/// Create a copy of EnglishDraftVocab
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnglishDraftVocabCopyWith<_EnglishDraftVocab> get copyWith => __$EnglishDraftVocabCopyWithImpl<_EnglishDraftVocab>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnglishDraftVocabToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnglishDraftVocab&&(identical(other.en, en) || other.en == en)&&(identical(other.hi, hi) || other.hi == hi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,en,hi);

@override
String toString() {
  return 'EnglishDraftVocab(en: $en, hi: $hi)';
}


}

/// @nodoc
abstract mixin class _$EnglishDraftVocabCopyWith<$Res> implements $EnglishDraftVocabCopyWith<$Res> {
  factory _$EnglishDraftVocabCopyWith(_EnglishDraftVocab value, $Res Function(_EnglishDraftVocab) _then) = __$EnglishDraftVocabCopyWithImpl;
@override @useResult
$Res call({
 String en, String hi
});




}
/// @nodoc
class __$EnglishDraftVocabCopyWithImpl<$Res>
    implements _$EnglishDraftVocabCopyWith<$Res> {
  __$EnglishDraftVocabCopyWithImpl(this._self, this._then);

  final _EnglishDraftVocab _self;
  final $Res Function(_EnglishDraftVocab) _then;

/// Create a copy of EnglishDraftVocab
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? en = null,Object? hi = null,}) {
  return _then(_EnglishDraftVocab(
en: null == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String,hi: null == hi ? _self.hi : hi // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$EnglishDraftAlternatives {

 EnglishDraftAlternativesTone get tone; String get text;
/// Create a copy of EnglishDraftAlternatives
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnglishDraftAlternativesCopyWith<EnglishDraftAlternatives> get copyWith => _$EnglishDraftAlternativesCopyWithImpl<EnglishDraftAlternatives>(this as EnglishDraftAlternatives, _$identity);

  /// Serializes this EnglishDraftAlternatives to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnglishDraftAlternatives&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tone,text);

@override
String toString() {
  return 'EnglishDraftAlternatives(tone: $tone, text: $text)';
}


}

/// @nodoc
abstract mixin class $EnglishDraftAlternativesCopyWith<$Res>  {
  factory $EnglishDraftAlternativesCopyWith(EnglishDraftAlternatives value, $Res Function(EnglishDraftAlternatives) _then) = _$EnglishDraftAlternativesCopyWithImpl;
@useResult
$Res call({
 EnglishDraftAlternativesTone tone, String text
});




}
/// @nodoc
class _$EnglishDraftAlternativesCopyWithImpl<$Res>
    implements $EnglishDraftAlternativesCopyWith<$Res> {
  _$EnglishDraftAlternativesCopyWithImpl(this._self, this._then);

  final EnglishDraftAlternatives _self;
  final $Res Function(EnglishDraftAlternatives) _then;

/// Create a copy of EnglishDraftAlternatives
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tone = null,Object? text = null,}) {
  return _then(_self.copyWith(
tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as EnglishDraftAlternativesTone,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EnglishDraftAlternatives].
extension EnglishDraftAlternativesPatterns on EnglishDraftAlternatives {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnglishDraftAlternatives value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnglishDraftAlternatives() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnglishDraftAlternatives value)  $default,){
final _that = this;
switch (_that) {
case _EnglishDraftAlternatives():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnglishDraftAlternatives value)?  $default,){
final _that = this;
switch (_that) {
case _EnglishDraftAlternatives() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EnglishDraftAlternativesTone tone,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnglishDraftAlternatives() when $default != null:
return $default(_that.tone,_that.text);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EnglishDraftAlternativesTone tone,  String text)  $default,) {final _that = this;
switch (_that) {
case _EnglishDraftAlternatives():
return $default(_that.tone,_that.text);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EnglishDraftAlternativesTone tone,  String text)?  $default,) {final _that = this;
switch (_that) {
case _EnglishDraftAlternatives() when $default != null:
return $default(_that.tone,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnglishDraftAlternatives implements EnglishDraftAlternatives {
  const _EnglishDraftAlternatives({required this.tone, required this.text});
  factory _EnglishDraftAlternatives.fromJson(Map<String, dynamic> json) => _$EnglishDraftAlternativesFromJson(json);

@override final  EnglishDraftAlternativesTone tone;
@override final  String text;

/// Create a copy of EnglishDraftAlternatives
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnglishDraftAlternativesCopyWith<_EnglishDraftAlternatives> get copyWith => __$EnglishDraftAlternativesCopyWithImpl<_EnglishDraftAlternatives>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnglishDraftAlternativesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnglishDraftAlternatives&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tone,text);

@override
String toString() {
  return 'EnglishDraftAlternatives(tone: $tone, text: $text)';
}


}

/// @nodoc
abstract mixin class _$EnglishDraftAlternativesCopyWith<$Res> implements $EnglishDraftAlternativesCopyWith<$Res> {
  factory _$EnglishDraftAlternativesCopyWith(_EnglishDraftAlternatives value, $Res Function(_EnglishDraftAlternatives) _then) = __$EnglishDraftAlternativesCopyWithImpl;
@override @useResult
$Res call({
 EnglishDraftAlternativesTone tone, String text
});




}
/// @nodoc
class __$EnglishDraftAlternativesCopyWithImpl<$Res>
    implements _$EnglishDraftAlternativesCopyWith<$Res> {
  __$EnglishDraftAlternativesCopyWithImpl(this._self, this._then);

  final _EnglishDraftAlternatives _self;
  final $Res Function(_EnglishDraftAlternatives) _then;

/// Create a copy of EnglishDraftAlternatives
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tone = null,Object? text = null,}) {
  return _then(_EnglishDraftAlternatives(
tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as EnglishDraftAlternativesTone,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Proofread {

 String get corrected; List<ProofreadFixes> get fixes; List<ProofreadAlternatives> get alternatives;
/// Create a copy of Proofread
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProofreadCopyWith<Proofread> get copyWith => _$ProofreadCopyWithImpl<Proofread>(this as Proofread, _$identity);

  /// Serializes this Proofread to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Proofread&&(identical(other.corrected, corrected) || other.corrected == corrected)&&const DeepCollectionEquality().equals(other.fixes, fixes)&&const DeepCollectionEquality().equals(other.alternatives, alternatives));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,corrected,const DeepCollectionEquality().hash(fixes),const DeepCollectionEquality().hash(alternatives));

@override
String toString() {
  return 'Proofread(corrected: $corrected, fixes: $fixes, alternatives: $alternatives)';
}


}

/// @nodoc
abstract mixin class $ProofreadCopyWith<$Res>  {
  factory $ProofreadCopyWith(Proofread value, $Res Function(Proofread) _then) = _$ProofreadCopyWithImpl;
@useResult
$Res call({
 String corrected, List<ProofreadFixes> fixes, List<ProofreadAlternatives> alternatives
});




}
/// @nodoc
class _$ProofreadCopyWithImpl<$Res>
    implements $ProofreadCopyWith<$Res> {
  _$ProofreadCopyWithImpl(this._self, this._then);

  final Proofread _self;
  final $Res Function(Proofread) _then;

/// Create a copy of Proofread
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? corrected = null,Object? fixes = null,Object? alternatives = null,}) {
  return _then(_self.copyWith(
corrected: null == corrected ? _self.corrected : corrected // ignore: cast_nullable_to_non_nullable
as String,fixes: null == fixes ? _self.fixes : fixes // ignore: cast_nullable_to_non_nullable
as List<ProofreadFixes>,alternatives: null == alternatives ? _self.alternatives : alternatives // ignore: cast_nullable_to_non_nullable
as List<ProofreadAlternatives>,
  ));
}

}


/// Adds pattern-matching-related methods to [Proofread].
extension ProofreadPatterns on Proofread {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Proofread value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Proofread() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Proofread value)  $default,){
final _that = this;
switch (_that) {
case _Proofread():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Proofread value)?  $default,){
final _that = this;
switch (_that) {
case _Proofread() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String corrected,  List<ProofreadFixes> fixes,  List<ProofreadAlternatives> alternatives)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Proofread() when $default != null:
return $default(_that.corrected,_that.fixes,_that.alternatives);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String corrected,  List<ProofreadFixes> fixes,  List<ProofreadAlternatives> alternatives)  $default,) {final _that = this;
switch (_that) {
case _Proofread():
return $default(_that.corrected,_that.fixes,_that.alternatives);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String corrected,  List<ProofreadFixes> fixes,  List<ProofreadAlternatives> alternatives)?  $default,) {final _that = this;
switch (_that) {
case _Proofread() when $default != null:
return $default(_that.corrected,_that.fixes,_that.alternatives);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Proofread implements Proofread {
  const _Proofread({required this.corrected, required final  List<ProofreadFixes> fixes, required final  List<ProofreadAlternatives> alternatives}): _fixes = fixes,_alternatives = alternatives;
  factory _Proofread.fromJson(Map<String, dynamic> json) => _$ProofreadFromJson(json);

@override final  String corrected;
 final  List<ProofreadFixes> _fixes;
@override List<ProofreadFixes> get fixes {
  if (_fixes is EqualUnmodifiableListView) return _fixes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fixes);
}

 final  List<ProofreadAlternatives> _alternatives;
@override List<ProofreadAlternatives> get alternatives {
  if (_alternatives is EqualUnmodifiableListView) return _alternatives;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alternatives);
}


/// Create a copy of Proofread
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProofreadCopyWith<_Proofread> get copyWith => __$ProofreadCopyWithImpl<_Proofread>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProofreadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Proofread&&(identical(other.corrected, corrected) || other.corrected == corrected)&&const DeepCollectionEquality().equals(other._fixes, _fixes)&&const DeepCollectionEquality().equals(other._alternatives, _alternatives));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,corrected,const DeepCollectionEquality().hash(_fixes),const DeepCollectionEquality().hash(_alternatives));

@override
String toString() {
  return 'Proofread(corrected: $corrected, fixes: $fixes, alternatives: $alternatives)';
}


}

/// @nodoc
abstract mixin class _$ProofreadCopyWith<$Res> implements $ProofreadCopyWith<$Res> {
  factory _$ProofreadCopyWith(_Proofread value, $Res Function(_Proofread) _then) = __$ProofreadCopyWithImpl;
@override @useResult
$Res call({
 String corrected, List<ProofreadFixes> fixes, List<ProofreadAlternatives> alternatives
});




}
/// @nodoc
class __$ProofreadCopyWithImpl<$Res>
    implements _$ProofreadCopyWith<$Res> {
  __$ProofreadCopyWithImpl(this._self, this._then);

  final _Proofread _self;
  final $Res Function(_Proofread) _then;

/// Create a copy of Proofread
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? corrected = null,Object? fixes = null,Object? alternatives = null,}) {
  return _then(_Proofread(
corrected: null == corrected ? _self.corrected : corrected // ignore: cast_nullable_to_non_nullable
as String,fixes: null == fixes ? _self._fixes : fixes // ignore: cast_nullable_to_non_nullable
as List<ProofreadFixes>,alternatives: null == alternatives ? _self._alternatives : alternatives // ignore: cast_nullable_to_non_nullable
as List<ProofreadAlternatives>,
  ));
}


}


/// @nodoc
mixin _$ProofreadAlternatives {

 ProofreadAlternativesTone get tone; String get text;
/// Create a copy of ProofreadAlternatives
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProofreadAlternativesCopyWith<ProofreadAlternatives> get copyWith => _$ProofreadAlternativesCopyWithImpl<ProofreadAlternatives>(this as ProofreadAlternatives, _$identity);

  /// Serializes this ProofreadAlternatives to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProofreadAlternatives&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tone,text);

@override
String toString() {
  return 'ProofreadAlternatives(tone: $tone, text: $text)';
}


}

/// @nodoc
abstract mixin class $ProofreadAlternativesCopyWith<$Res>  {
  factory $ProofreadAlternativesCopyWith(ProofreadAlternatives value, $Res Function(ProofreadAlternatives) _then) = _$ProofreadAlternativesCopyWithImpl;
@useResult
$Res call({
 ProofreadAlternativesTone tone, String text
});




}
/// @nodoc
class _$ProofreadAlternativesCopyWithImpl<$Res>
    implements $ProofreadAlternativesCopyWith<$Res> {
  _$ProofreadAlternativesCopyWithImpl(this._self, this._then);

  final ProofreadAlternatives _self;
  final $Res Function(ProofreadAlternatives) _then;

/// Create a copy of ProofreadAlternatives
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tone = null,Object? text = null,}) {
  return _then(_self.copyWith(
tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as ProofreadAlternativesTone,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProofreadAlternatives].
extension ProofreadAlternativesPatterns on ProofreadAlternatives {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProofreadAlternatives value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProofreadAlternatives() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProofreadAlternatives value)  $default,){
final _that = this;
switch (_that) {
case _ProofreadAlternatives():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProofreadAlternatives value)?  $default,){
final _that = this;
switch (_that) {
case _ProofreadAlternatives() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProofreadAlternativesTone tone,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProofreadAlternatives() when $default != null:
return $default(_that.tone,_that.text);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProofreadAlternativesTone tone,  String text)  $default,) {final _that = this;
switch (_that) {
case _ProofreadAlternatives():
return $default(_that.tone,_that.text);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProofreadAlternativesTone tone,  String text)?  $default,) {final _that = this;
switch (_that) {
case _ProofreadAlternatives() when $default != null:
return $default(_that.tone,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProofreadAlternatives implements ProofreadAlternatives {
  const _ProofreadAlternatives({required this.tone, required this.text});
  factory _ProofreadAlternatives.fromJson(Map<String, dynamic> json) => _$ProofreadAlternativesFromJson(json);

@override final  ProofreadAlternativesTone tone;
@override final  String text;

/// Create a copy of ProofreadAlternatives
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProofreadAlternativesCopyWith<_ProofreadAlternatives> get copyWith => __$ProofreadAlternativesCopyWithImpl<_ProofreadAlternatives>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProofreadAlternativesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProofreadAlternatives&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tone,text);

@override
String toString() {
  return 'ProofreadAlternatives(tone: $tone, text: $text)';
}


}

/// @nodoc
abstract mixin class _$ProofreadAlternativesCopyWith<$Res> implements $ProofreadAlternativesCopyWith<$Res> {
  factory _$ProofreadAlternativesCopyWith(_ProofreadAlternatives value, $Res Function(_ProofreadAlternatives) _then) = __$ProofreadAlternativesCopyWithImpl;
@override @useResult
$Res call({
 ProofreadAlternativesTone tone, String text
});




}
/// @nodoc
class __$ProofreadAlternativesCopyWithImpl<$Res>
    implements _$ProofreadAlternativesCopyWith<$Res> {
  __$ProofreadAlternativesCopyWithImpl(this._self, this._then);

  final _ProofreadAlternatives _self;
  final $Res Function(_ProofreadAlternatives) _then;

/// Create a copy of ProofreadAlternatives
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tone = null,Object? text = null,}) {
  return _then(_ProofreadAlternatives(
tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as ProofreadAlternativesTone,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProofreadFixes {

 String get wrong; String get right; ProofreadFixesKind get kind; String get why;
/// Create a copy of ProofreadFixes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProofreadFixesCopyWith<ProofreadFixes> get copyWith => _$ProofreadFixesCopyWithImpl<ProofreadFixes>(this as ProofreadFixes, _$identity);

  /// Serializes this ProofreadFixes to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProofreadFixes&&(identical(other.wrong, wrong) || other.wrong == wrong)&&(identical(other.right, right) || other.right == right)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.why, why) || other.why == why));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wrong,right,kind,why);

@override
String toString() {
  return 'ProofreadFixes(wrong: $wrong, right: $right, kind: $kind, why: $why)';
}


}

/// @nodoc
abstract mixin class $ProofreadFixesCopyWith<$Res>  {
  factory $ProofreadFixesCopyWith(ProofreadFixes value, $Res Function(ProofreadFixes) _then) = _$ProofreadFixesCopyWithImpl;
@useResult
$Res call({
 String wrong, String right, ProofreadFixesKind kind, String why
});




}
/// @nodoc
class _$ProofreadFixesCopyWithImpl<$Res>
    implements $ProofreadFixesCopyWith<$Res> {
  _$ProofreadFixesCopyWithImpl(this._self, this._then);

  final ProofreadFixes _self;
  final $Res Function(ProofreadFixes) _then;

/// Create a copy of ProofreadFixes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? wrong = null,Object? right = null,Object? kind = null,Object? why = null,}) {
  return _then(_self.copyWith(
wrong: null == wrong ? _self.wrong : wrong // ignore: cast_nullable_to_non_nullable
as String,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ProofreadFixesKind,why: null == why ? _self.why : why // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProofreadFixes].
extension ProofreadFixesPatterns on ProofreadFixes {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProofreadFixes value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProofreadFixes() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProofreadFixes value)  $default,){
final _that = this;
switch (_that) {
case _ProofreadFixes():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProofreadFixes value)?  $default,){
final _that = this;
switch (_that) {
case _ProofreadFixes() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String wrong,  String right,  ProofreadFixesKind kind,  String why)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProofreadFixes() when $default != null:
return $default(_that.wrong,_that.right,_that.kind,_that.why);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String wrong,  String right,  ProofreadFixesKind kind,  String why)  $default,) {final _that = this;
switch (_that) {
case _ProofreadFixes():
return $default(_that.wrong,_that.right,_that.kind,_that.why);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String wrong,  String right,  ProofreadFixesKind kind,  String why)?  $default,) {final _that = this;
switch (_that) {
case _ProofreadFixes() when $default != null:
return $default(_that.wrong,_that.right,_that.kind,_that.why);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProofreadFixes implements ProofreadFixes {
  const _ProofreadFixes({required this.wrong, required this.right, required this.kind, required this.why});
  factory _ProofreadFixes.fromJson(Map<String, dynamic> json) => _$ProofreadFixesFromJson(json);

@override final  String wrong;
@override final  String right;
@override final  ProofreadFixesKind kind;
@override final  String why;

/// Create a copy of ProofreadFixes
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProofreadFixesCopyWith<_ProofreadFixes> get copyWith => __$ProofreadFixesCopyWithImpl<_ProofreadFixes>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProofreadFixesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProofreadFixes&&(identical(other.wrong, wrong) || other.wrong == wrong)&&(identical(other.right, right) || other.right == right)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.why, why) || other.why == why));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wrong,right,kind,why);

@override
String toString() {
  return 'ProofreadFixes(wrong: $wrong, right: $right, kind: $kind, why: $why)';
}


}

/// @nodoc
abstract mixin class _$ProofreadFixesCopyWith<$Res> implements $ProofreadFixesCopyWith<$Res> {
  factory _$ProofreadFixesCopyWith(_ProofreadFixes value, $Res Function(_ProofreadFixes) _then) = __$ProofreadFixesCopyWithImpl;
@override @useResult
$Res call({
 String wrong, String right, ProofreadFixesKind kind, String why
});




}
/// @nodoc
class __$ProofreadFixesCopyWithImpl<$Res>
    implements _$ProofreadFixesCopyWith<$Res> {
  __$ProofreadFixesCopyWithImpl(this._self, this._then);

  final _ProofreadFixes _self;
  final $Res Function(_ProofreadFixes) _then;

/// Create a copy of ProofreadFixes
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? wrong = null,Object? right = null,Object? kind = null,Object? why = null,}) {
  return _then(_ProofreadFixes(
wrong: null == wrong ? _self.wrong : wrong // ignore: cast_nullable_to_non_nullable
as String,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ProofreadFixesKind,why: null == why ? _self.why : why // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CoachTurn {

 String get reply; String get replyHindi; CoachTurnBetter? get better; bool? get closing;
/// Create a copy of CoachTurn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachTurnCopyWith<CoachTurn> get copyWith => _$CoachTurnCopyWithImpl<CoachTurn>(this as CoachTurn, _$identity);

  /// Serializes this CoachTurn to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachTurn&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.replyHindi, replyHindi) || other.replyHindi == replyHindi)&&(identical(other.better, better) || other.better == better)&&(identical(other.closing, closing) || other.closing == closing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reply,replyHindi,better,closing);

@override
String toString() {
  return 'CoachTurn(reply: $reply, replyHindi: $replyHindi, better: $better, closing: $closing)';
}


}

/// @nodoc
abstract mixin class $CoachTurnCopyWith<$Res>  {
  factory $CoachTurnCopyWith(CoachTurn value, $Res Function(CoachTurn) _then) = _$CoachTurnCopyWithImpl;
@useResult
$Res call({
 String reply, String replyHindi, CoachTurnBetter? better, bool? closing
});


$CoachTurnBetterCopyWith<$Res>? get better;

}
/// @nodoc
class _$CoachTurnCopyWithImpl<$Res>
    implements $CoachTurnCopyWith<$Res> {
  _$CoachTurnCopyWithImpl(this._self, this._then);

  final CoachTurn _self;
  final $Res Function(CoachTurn) _then;

/// Create a copy of CoachTurn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reply = null,Object? replyHindi = null,Object? better = freezed,Object? closing = freezed,}) {
  return _then(_self.copyWith(
reply: null == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String,replyHindi: null == replyHindi ? _self.replyHindi : replyHindi // ignore: cast_nullable_to_non_nullable
as String,better: freezed == better ? _self.better : better // ignore: cast_nullable_to_non_nullable
as CoachTurnBetter?,closing: freezed == closing ? _self.closing : closing // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of CoachTurn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoachTurnBetterCopyWith<$Res>? get better {
    if (_self.better == null) {
    return null;
  }

  return $CoachTurnBetterCopyWith<$Res>(_self.better!, (value) {
    return _then(_self.copyWith(better: value));
  });
}
}


/// Adds pattern-matching-related methods to [CoachTurn].
extension CoachTurnPatterns on CoachTurn {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachTurn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachTurn() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachTurn value)  $default,){
final _that = this;
switch (_that) {
case _CoachTurn():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachTurn value)?  $default,){
final _that = this;
switch (_that) {
case _CoachTurn() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String reply,  String replyHindi,  CoachTurnBetter? better,  bool? closing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachTurn() when $default != null:
return $default(_that.reply,_that.replyHindi,_that.better,_that.closing);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String reply,  String replyHindi,  CoachTurnBetter? better,  bool? closing)  $default,) {final _that = this;
switch (_that) {
case _CoachTurn():
return $default(_that.reply,_that.replyHindi,_that.better,_that.closing);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String reply,  String replyHindi,  CoachTurnBetter? better,  bool? closing)?  $default,) {final _that = this;
switch (_that) {
case _CoachTurn() when $default != null:
return $default(_that.reply,_that.replyHindi,_that.better,_that.closing);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CoachTurn implements CoachTurn {
  const _CoachTurn({required this.reply, required this.replyHindi, this.better, this.closing});
  factory _CoachTurn.fromJson(Map<String, dynamic> json) => _$CoachTurnFromJson(json);

@override final  String reply;
@override final  String replyHindi;
@override final  CoachTurnBetter? better;
@override final  bool? closing;

/// Create a copy of CoachTurn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachTurnCopyWith<_CoachTurn> get copyWith => __$CoachTurnCopyWithImpl<_CoachTurn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoachTurnToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachTurn&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.replyHindi, replyHindi) || other.replyHindi == replyHindi)&&(identical(other.better, better) || other.better == better)&&(identical(other.closing, closing) || other.closing == closing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reply,replyHindi,better,closing);

@override
String toString() {
  return 'CoachTurn(reply: $reply, replyHindi: $replyHindi, better: $better, closing: $closing)';
}


}

/// @nodoc
abstract mixin class _$CoachTurnCopyWith<$Res> implements $CoachTurnCopyWith<$Res> {
  factory _$CoachTurnCopyWith(_CoachTurn value, $Res Function(_CoachTurn) _then) = __$CoachTurnCopyWithImpl;
@override @useResult
$Res call({
 String reply, String replyHindi, CoachTurnBetter? better, bool? closing
});


@override $CoachTurnBetterCopyWith<$Res>? get better;

}
/// @nodoc
class __$CoachTurnCopyWithImpl<$Res>
    implements _$CoachTurnCopyWith<$Res> {
  __$CoachTurnCopyWithImpl(this._self, this._then);

  final _CoachTurn _self;
  final $Res Function(_CoachTurn) _then;

/// Create a copy of CoachTurn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reply = null,Object? replyHindi = null,Object? better = freezed,Object? closing = freezed,}) {
  return _then(_CoachTurn(
reply: null == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String,replyHindi: null == replyHindi ? _self.replyHindi : replyHindi // ignore: cast_nullable_to_non_nullable
as String,better: freezed == better ? _self.better : better // ignore: cast_nullable_to_non_nullable
as CoachTurnBetter?,closing: freezed == closing ? _self.closing : closing // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of CoachTurn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoachTurnBetterCopyWith<$Res>? get better {
    if (_self.better == null) {
    return null;
  }

  return $CoachTurnBetterCopyWith<$Res>(_self.better!, (value) {
    return _then(_self.copyWith(better: value));
  });
}
}


/// @nodoc
mixin _$CoachTurnBetter {

 String get text; String get why;
/// Create a copy of CoachTurnBetter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachTurnBetterCopyWith<CoachTurnBetter> get copyWith => _$CoachTurnBetterCopyWithImpl<CoachTurnBetter>(this as CoachTurnBetter, _$identity);

  /// Serializes this CoachTurnBetter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachTurnBetter&&(identical(other.text, text) || other.text == text)&&(identical(other.why, why) || other.why == why));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,why);

@override
String toString() {
  return 'CoachTurnBetter(text: $text, why: $why)';
}


}

/// @nodoc
abstract mixin class $CoachTurnBetterCopyWith<$Res>  {
  factory $CoachTurnBetterCopyWith(CoachTurnBetter value, $Res Function(CoachTurnBetter) _then) = _$CoachTurnBetterCopyWithImpl;
@useResult
$Res call({
 String text, String why
});




}
/// @nodoc
class _$CoachTurnBetterCopyWithImpl<$Res>
    implements $CoachTurnBetterCopyWith<$Res> {
  _$CoachTurnBetterCopyWithImpl(this._self, this._then);

  final CoachTurnBetter _self;
  final $Res Function(CoachTurnBetter) _then;

/// Create a copy of CoachTurnBetter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? why = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,why: null == why ? _self.why : why // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CoachTurnBetter].
extension CoachTurnBetterPatterns on CoachTurnBetter {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachTurnBetter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachTurnBetter() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachTurnBetter value)  $default,){
final _that = this;
switch (_that) {
case _CoachTurnBetter():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachTurnBetter value)?  $default,){
final _that = this;
switch (_that) {
case _CoachTurnBetter() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  String why)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachTurnBetter() when $default != null:
return $default(_that.text,_that.why);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  String why)  $default,) {final _that = this;
switch (_that) {
case _CoachTurnBetter():
return $default(_that.text,_that.why);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  String why)?  $default,) {final _that = this;
switch (_that) {
case _CoachTurnBetter() when $default != null:
return $default(_that.text,_that.why);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CoachTurnBetter implements CoachTurnBetter {
  const _CoachTurnBetter({required this.text, required this.why});
  factory _CoachTurnBetter.fromJson(Map<String, dynamic> json) => _$CoachTurnBetterFromJson(json);

@override final  String text;
@override final  String why;

/// Create a copy of CoachTurnBetter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachTurnBetterCopyWith<_CoachTurnBetter> get copyWith => __$CoachTurnBetterCopyWithImpl<_CoachTurnBetter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoachTurnBetterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachTurnBetter&&(identical(other.text, text) || other.text == text)&&(identical(other.why, why) || other.why == why));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,why);

@override
String toString() {
  return 'CoachTurnBetter(text: $text, why: $why)';
}


}

/// @nodoc
abstract mixin class _$CoachTurnBetterCopyWith<$Res> implements $CoachTurnBetterCopyWith<$Res> {
  factory _$CoachTurnBetterCopyWith(_CoachTurnBetter value, $Res Function(_CoachTurnBetter) _then) = __$CoachTurnBetterCopyWithImpl;
@override @useResult
$Res call({
 String text, String why
});




}
/// @nodoc
class __$CoachTurnBetterCopyWithImpl<$Res>
    implements _$CoachTurnBetterCopyWith<$Res> {
  __$CoachTurnBetterCopyWithImpl(this._self, this._then);

  final _CoachTurnBetter _self;
  final $Res Function(_CoachTurnBetter) _then;

/// Create a copy of CoachTurnBetter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? why = null,}) {
  return _then(_CoachTurnBetter(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,why: null == why ? _self.why : why // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ApiError {

 ApiErrorCode get code; String get message; List<String>? get suggestions;
/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiErrorCopyWith<ApiError> get copyWith => _$ApiErrorCopyWithImpl<ApiError>(this as ApiError, _$identity);

  /// Serializes this ApiError to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.suggestions, suggestions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(suggestions));

@override
String toString() {
  return 'ApiError(code: $code, message: $message, suggestions: $suggestions)';
}


}

/// @nodoc
abstract mixin class $ApiErrorCopyWith<$Res>  {
  factory $ApiErrorCopyWith(ApiError value, $Res Function(ApiError) _then) = _$ApiErrorCopyWithImpl;
@useResult
$Res call({
 ApiErrorCode code, String message, List<String>? suggestions
});




}
/// @nodoc
class _$ApiErrorCopyWithImpl<$Res>
    implements $ApiErrorCopyWith<$Res> {
  _$ApiErrorCopyWithImpl(this._self, this._then);

  final ApiError _self;
  final $Res Function(ApiError) _then;

/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? suggestions = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as ApiErrorCode,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,suggestions: freezed == suggestions ? _self.suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiError].
extension ApiErrorPatterns on ApiError {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiError() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiError value)  $default,){
final _that = this;
switch (_that) {
case _ApiError():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiError value)?  $default,){
final _that = this;
switch (_that) {
case _ApiError() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ApiErrorCode code,  String message,  List<String>? suggestions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiError() when $default != null:
return $default(_that.code,_that.message,_that.suggestions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ApiErrorCode code,  String message,  List<String>? suggestions)  $default,) {final _that = this;
switch (_that) {
case _ApiError():
return $default(_that.code,_that.message,_that.suggestions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ApiErrorCode code,  String message,  List<String>? suggestions)?  $default,) {final _that = this;
switch (_that) {
case _ApiError() when $default != null:
return $default(_that.code,_that.message,_that.suggestions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApiError implements ApiError {
  const _ApiError({required this.code, required this.message, final  List<String>? suggestions}): _suggestions = suggestions;
  factory _ApiError.fromJson(Map<String, dynamic> json) => _$ApiErrorFromJson(json);

@override final  ApiErrorCode code;
@override final  String message;
 final  List<String>? _suggestions;
@override List<String>? get suggestions {
  final value = _suggestions;
  if (value == null) return null;
  if (_suggestions is EqualUnmodifiableListView) return _suggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiErrorCopyWith<_ApiError> get copyWith => __$ApiErrorCopyWithImpl<_ApiError>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApiErrorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._suggestions, _suggestions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(_suggestions));

@override
String toString() {
  return 'ApiError(code: $code, message: $message, suggestions: $suggestions)';
}


}

/// @nodoc
abstract mixin class _$ApiErrorCopyWith<$Res> implements $ApiErrorCopyWith<$Res> {
  factory _$ApiErrorCopyWith(_ApiError value, $Res Function(_ApiError) _then) = __$ApiErrorCopyWithImpl;
@override @useResult
$Res call({
 ApiErrorCode code, String message, List<String>? suggestions
});




}
/// @nodoc
class __$ApiErrorCopyWithImpl<$Res>
    implements _$ApiErrorCopyWith<$Res> {
  __$ApiErrorCopyWithImpl(this._self, this._then);

  final _ApiError _self;
  final $Res Function(_ApiError) _then;

/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? suggestions = freezed,}) {
  return _then(_ApiError(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as ApiErrorCode,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,suggestions: freezed == suggestions ? _self._suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
