enum UserCharacter {
  boy('boy', 'svg/body-boy.svg', 'svg/eat-boy.svg'),
  girl('girl', 'svg/body-girl.svg', 'svg/eat-girl.svg');

  const UserCharacter(this.wire, this.bodyAsset, this.eatAsset);

  final String wire;
  final String bodyAsset;
  final String eatAsset;

  String toWire() => wire;

  static UserCharacter fromWire(Object? value) {
    return switch (value) {
      'girl' => UserCharacter.girl,
      _ => UserCharacter.boy,
    };
  }
}
