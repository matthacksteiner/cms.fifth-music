(() => {
	(function () {
		"use strict";
		var _ = function () {
				var n = this,
					r = n.$createElement,
					a = n._self._c || r;
				return a(
					"div",
					{ staticClass: "k-block-type-grid", on: { dblclick: n.open } },
					[
						a(
							"k-layout-field",
							n._b(
								{
									attrs: { value: n.content.grid, label: n.content.title },
									on: { input: n.update },
								},
								"k-layout-field",
								n.grid,
								!1
							)
						),
					],
					1
				);
			},
			c = [];
		function v(n, r, a, m, o, l, d, C) {
			var e = typeof n == "function" ? n.options : n;
			r && ((e.render = r), (e.staticRenderFns = a), (e._compiled = !0)),
				m && (e.functional = !0),
				l && (e._scopeId = "data-v-" + l);
			var i;
			if (
				(d
					? ((i = function (t) {
							(t =
								t ||
								(this.$vnode && this.$vnode.ssrContext) ||
								(this.parent &&
									this.parent.$vnode &&
									this.parent.$vnode.ssrContext)),
								!t &&
									typeof __VUE_SSR_CONTEXT__ != "undefined" &&
									(t = __VUE_SSR_CONTEXT__),
								o && o.call(this, t),
								t && t._registeredComponents && t._registeredComponents.add(d);
					  }),
					  (e._ssrRegister = i))
					: o &&
					  (i = C
							? function () {
									o.call(
										this,
										(e.functional ? this.parent : this).$root.$options
											.shadowRoot
									);
							  }
							: o),
				i)
			)
				if (e.functional) {
					e._injectStyles = i;
					var b = e.render;
					e.render = function (k, u) {
						return i.call(u), b(k, u);
					};
				} else {
					var f = e.beforeCreate;
					e.beforeCreate = f ? [].concat(f, i) : [i];
				}
			return { exports: n, options: e };
		}
		const h = {
				computed: {
					grid() {
						return this.field("grid");
					},
				},
			},
			s = {};
		var p = v(h, _, c, !1, V, null, null, null);
		function V(n) {
			for (let r in s) this[r] = s[r];
		}
		var g = (function () {
				return p.exports;
			})(),
			H = "";
		window.panel.plugin("baukasten/grid-blocks", {
			blocks: { grid: g },
			icons: {
				grid: '<path d="M0.1,0.1V5v1.5V10v1.5v4.9h16.3v-4.9V10V6.5V5V0.1H0.1z M1.5,6.5h4.1V10H1.5V6.5z M14.9,14.9H1.5v-3.4h4.1h1.4h7.8V14.9zM14.9,10H7.1V6.5h7.8V10z M7.1,5H5.6H1.5V1.6h13.4V5H7.1z"/>',
			},
		});
	})();
})();
