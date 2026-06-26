using UnityEngine;
using DriftLands.Core;

namespace DriftLands.Mono
{
    /// <summary>
    /// Demonstrates wiring the engine-agnostic DriftLands core into a Unity
    /// MonoBehaviour: the same Stats/Upgrades/Equipment/Progression/Combat that
    /// drive the Godot build also drive this Unity actor. This is the Unity face
    /// of the shared design — the algorithms live in DriftLands.Core, the engine
    /// only provides movement, rendering, and input.
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class PlayerController : MonoBehaviour
    {
        [SerializeField] private float _attackInterval = 0.45f;

        private Stats _stats;
        private readonly Progression _progression = new Progression();
        private readonly Equipment _equipment = new Equipment();
        private readonly MetaProgress _meta = new MetaProgress();
        private readonly System.Random _rng = new System.Random();
        private float _attackCooldown;

        private void Awake()
        {
            RecomputeStats();
        }

        private void RecomputeStats()
        {
            var withMeta = Upgrades.ApplyTo(Stats.PlayerBase(), _meta);
            _stats = withMeta.Add(_equipment.TotalMods());
        }

        private void Update()
        {
            var dir = new Vector3(Input.GetAxisRaw("Horizontal"), Input.GetAxisRaw("Vertical"), 0f);
            if (dir.sqrMagnitude > 0.01f)
                transform.position += dir.normalized * _stats.MoveSpeed * Time.deltaTime;

            _attackCooldown = Mathf.Max(0f, _attackCooldown - Time.deltaTime);
        }

        /// <summary>Resolve a hit against a target using the shared combat math.</summary>
        public int Strike(Stats target)
        {
            if (_attackCooldown > 0f)
                return 0;
            _attackCooldown = _attackInterval / Mathf.Max(0.35f, _stats.AttackSpeed);
            return Combat.Resolve(_stats, target, _rng).Damage;
        }

        public void CollectItem(Item item)
        {
            var current = _equipment.Get(item.Slot);
            if (current == null || item.Power() > current.Power())
                _equipment.Equip(item);
            RecomputeStats();
        }

        public void GainXp(int amount) => _progression.AddXp(amount);

        public int Level => _progression.Level;
    }
}
